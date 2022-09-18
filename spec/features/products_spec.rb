require 'rails_helper'
require 'shared/session_helper'
require 'shared/products_spec_helper'
require 'shared/users_spec_helper'

include SessionHelper
include ProductsSpecHelper
include UsersSpecHelper

RSpec.describe ::Spree::Product do
  before(:all) do
    setup_all_for_posting_products
    Capybara.ignore_hidden_elements = false
    ::Spree::User.delete_all
  end

  after(:all) do
    cleanup_retail_products
  end

  describe 'create product', type: :feature do
    # routes { Spree::Core::Engine.routes }
    let :first_user_attr do
      attributes_for(:another_user)
    end
    let :user_attr do
      attributes_for(:basic_user)
    end
    let(:sample_image_url) { 'http://digg.com/static/images/apple/apple-touch-icon-57.png' }
    let(:sample_fixture_file_name) { 'color_markers.jpg' }
    let(:sample_image_path) { File.join(ActionDispatch::IntegrationTest.fixture_path, 'files', sample_fixture_file_name) }

    context 'Convert from Retail::Product' do
      it 'Convert from sample product' do
        retail_product = create_retail_product(:shirt_retail_product, [sample_image_url])
        retail_site = ::Retail::Site.find_or_create_by!(name: 'ioffer') do |site|
          site.domain = 'ioffer.com'
          site.site_scraper = 'Scraper::Ioffer'
        end
        retail_store = ::Retail::Store.find_or_create_by!(retail_site_id: retail_site.id, retail_site_store_id: first_user_attr[:username]) do |store|
          store.name = first_user_attr[:username]
          store.store_url = "https://www.ioffer.com/selling/#{first_user_attr[:username]}"
        end
        retail_product.retail_store_id = retail_store.id
        retail_product.save
        retail_product.retail_store.reload
        expect(retail_product.leaf_site_category).not_to be_nil
        expect(retail_product.leaf_site_category.mapped_taxon_id).not_to be_nil

        # is find_by_full_path
        sku = 'ION8981'
        product = retail_product.create_as_spree_product(false, sku: sku)
        expect(product.name).to eq(retail_product.title)
        expect(product.price).to eq(retail_product.price)
        expect(product.sku).to eq(sku)
        if product.taxons.present? && retail_product.leaf_site_category.mapped_taxon # sometimes mappings b/w SiteCategory and Category don't work
          expect(product.taxons.under_categories.first.id).to eq(retail_product.leaf_site_category.mapped_taxon_id)
        end
        migration = ::Retail::ProductToSpreeProduct.where(retail_product_id: retail_product.id, spree_product_id: product.id).first
        expect(migration).not_to be_nil
        retail_product.reload
        expect(retail_product.migrations.collect(&:spree_product_id).include?(product.id)).to be_truthy
        expect(retail_product.spree_products.collect(&:id).include?(product.id)).to be_truthy
        product.reload
        expect(product.migration).not_to be_nil
        expect(product.migration.retail_product_id).to eq(retail_product.id)

        # properties
        matching_color_property = product.product_properties.includes(:property).find { |p| p.property.name == 'color' && (p.value == 'blue white' || p.value == 'white blue') }
        expect(matching_color_property).not_to be_nil

        matching_material_property = product.product_properties.includes(:property).find { |p| p.property.name == 'material' && p.value == 'cotton' }
        expect(matching_material_property).not_to be_nil

        # variants
        variant_ids = product.variants_including_master.all.collect(&:id)
        option_value_variants = ::Spree::OptionValuesVariant.where(variant_id: variant_ids).includes(:option_value)
        %w|white blue|.each do |_color|
          matching_color_value = option_value_variants.find { |ovv| ovv.option_value.option_type.name == 'color' && ovv.option_value.name == _color }
          expect(matching_color_value).not_to be_nil
        end
        matching_cotton_value = option_value_variants.find { |ovv| ovv.option_value.option_type.name == 'material' && ovv.option_value.name == 'cotton' }
        expect(matching_cotton_value).not_to be_nil

        # Download could be problem
        actual_product_photos_count = retail_product.product_photos.collect(&:image_url).compact.size
        expect(product.gallery.images.size).to eq(actual_product_photos_count)

        # Another user wants post this product
        user = sign_up_with(user_attr[:email], 'test1234', user_attr[:username], user_attr[:display_name])
        expect(user).not_to be_nil

        puts '  Create another product based on this master ---------------------------'
        page.driver.get spree.new_admin_product_path(product: {master_product_id: product.id})
        click_button 'Create'

        latest_product = ::Spree::Product.last
        expect(latest_product.id).not_to eq(product.id)
        expect(latest_product.master_product_id).to eq(product.id)
        expect(latest_product.user_id).to eq(user.id)
        expect(latest_product.master).not_to be_nil
        expect(latest_product.master.user_id).to eq(user.id)
        expect(latest_product.images.size).to eq(product.images.size)
        expect(latest_product.sku).not_to eq(sku)
      end
    end

    context 'Create Product Via Page Request' do

      it 'Create Product with Images' do
        user = signup_sample_user(:basic_user)
        price_attr = [{currency: 'USD', amount: 50.0},
          {currency: 'EUR', amount: 48.0}, {currency: 'JPY', amount: 4500.0 } ]
        product_attr = attributes_for(:basic_product)
        product_attr[:price_attributes] = price_attr

        product_before = ::Spree::Product.where(user_id: user.id).last
        no_price_product_attr = attributes_for(:no_price_product)

        puts '-- Try posting product w/o price'
        post admin_products_path(product: no_price_product_attr)
        last_product = ::Spree::Product.where(user_id: user.id).where('id > ?', product_before.try(:id)).last
        expect(last_product).to be_nil

        puts '-- Try posting product w/ currency prices'
        basic_product = post_product_via_requests(user, :basic_product,
          # { images: [sample_image_path], price_attributes: price_attr} )
          { price_attributes: price_attr} )

        shirt_product = post_product_via_requests(user, :shirt_product, { price: 33.5 } )
        expect(shirt_product.price).to eq 33.5
        expect(shirt_product.prices.count).to eq 1

        put admin_product_path(shirt_product, product:{ taxon_ids: basic_product.taxons.collect{|t| t.id.to_s }.join(',') } )
        shirt_product.reload
        expect(shirt_product.taxons.collect(&:id) ).to eq basic_product.taxons.collect(&:id)
      end
    end

  end
end