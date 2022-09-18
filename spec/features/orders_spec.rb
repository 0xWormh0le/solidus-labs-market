require 'rails_helper'
require 'shared/session_helper'
require 'shared/stores_spec_helper'
require 'shared/products_spec_helper'
require 'shared/users_spec_helper'

include SessionHelper
include StoresSpecHelper
include ProductsSpecHelper
include UsersSpecHelper

RSpec.describe ::Spree::Order do
  let(:sample_fixture_file_name) { 'files/color_markers.jpg' }
  let(:sample_image_path) { File.join(ActionDispatch::IntegrationTest.fixture_path,  sample_fixture_file_name) }

  before(:all) do
    setup_all_store_settings
    setup_all_for_posting_products
    # Capybara.ignore_hidden_elements = false
    Spree::Config[:track_inventory_levels] = false
    create(:state_ma)
    Spree::Config[:default_country_id] = Spree::Country.first.id
  end

  after(:all) do
    cleanup_retail_products
  end

  describe 'Order Product' do

    context 'Order no-other-variant via cart, Checkout Sequentially' do

      it 'Create Product with Images' do
        seller = signup_sample_user(:basic_user)

        product = post_product_via_requests(seller, :basic_product)

        visit logout_path
        buyer = signup_sample_user(:buyer_2)

        order = add_product_to_cart(buyer, product)

        proceed_to_checkout(order)
      end
    end

    context 'Order no-other-variant via cart, Checkout Together' do

      it 'Succeed with Checkout Together' do
        seller = signup_sample_user(:basic_user)

        product = post_product_via_requests(seller, :basic_product)

        visit logout_path
        buyer = signup_sample_user(:buyer_2)

        order = add_product_to_cart(buyer, product)

        checkout_together(order)
      end
    end

  end
end

##
# Changed the style of tests: from HTML elements interactions to manual making of requests.
# @return <Spree::Order> The order in cart state
def add_product_to_cart(user, product_or_variant)
  variant = product_or_variant.is_a?(::Spree::Product) ? product_or_variant.master : product_or_variant
  product = product_or_variant.is_a?(::Spree::Product) ? product_or_variant : product_or_variant.product
  if product_or_variant.is_a?(::Spree::Product)
    visit product_path(product)
    # click_button 'Add To Cart' #
  else
    visit variant_path(id: variant.id)
    # TODO: handle selecting variant and Add to Cart
  end
  post populate_orders_path(variant_id: variant.id, quantity: 1)

  order = Spree::Order.where(user_id: user.id, state:'cart').last
  expect(order).not_to be_nil
  line_item = order.line_items.where(variant_id: variant.id).last
  expect(line_item).not_to be_nil
  order
end


def prepare_address_attributes(address)
  address_attr = {}
  [:firstname, :lastname, :address1, :address2, :city, :state_id, :zipcode, :country_id, :phone, :id].each{|a| address_attr[a] = address.send(a) }
  address_attr
end

def submit_billing_address(order, address)
  patch update_checkout_path(
    state: 'address', order_id: order.id, save_user_address: true,
    order: { email: order.user.email,
      bill_address_attributes: prepare_address_attributes(address),
      use_billing: true } )
end

def proceed_to_checkout(order)
  visit cart_path
  checkout_url = nil
  find_all(:xpath, "//a[contains(@class,'checkout')]").each do|n|
    if n[:href].include?("order_id=#{order.id}")
      checkout_url = n[:href]
    end
  end
  expect(checkout_url).not_to be_nil

  visit checkout_url
  billing_addr_label = page.body.match( Regexp.new(I18n.t('spree.billing_address'), Regexp::IGNORECASE) )
  expect(billing_addr_label).not_to be_nil

  address = order.user.addresses.last || create(:basic_address)
  submit_billing_address(order, address)
  follow_redirect!

  # Should be delivery step next.  So far not working for test
  order.reload
  expect(order.state).to eq('delivery')
end

def checkout_together(order)
  address = order.user.addresses.last || create(:basic_address)
  shipments = ::Spree::Config.stock.coordinator_class.new(order).shipments
  shipments.each(&:save)
  payment_method = order.available_payment_methods.find{|p| p.name =~ /credit\scard/i } ||
    order.available_payment_methods.first

  basic_params = { order_id: order.id, state: 'address', save_user_address: true,
                   transaction_code: order.transaction_code }

  the_shipment = (order.shipments.first || shipments.first)
  selected_shipping_rate_id = the_shipment.try(:shipping_rates).try(:first).try(:id)

  post checkout_update_all_path(
    basic_params.merge(
      order: { email: order.user.email,
        bill_address_attributes: prepare_address_attributes(address),
        use_billing: true,
        shipments_attributes: { '0' => {
          selected_shipping_rate_id: selected_shipping_rate_id,
          id: the_shipment.id } },
        payment_attributes: [{ payment_method_id: payment_method.id} ] }
    ) )
  order.reload
  expect(order.completed?).to eq(false)
  expect(order.state).to eq('confirm')

end