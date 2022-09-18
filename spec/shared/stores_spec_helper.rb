module StoresSpecHelper
  ##
  # Spree's model structure is just too complex. Need to create default entries
  # for each of the models like StockLocation, ShippingMethod, ShippingRate, TaxRate,
  # Zone, ZoneMember
  def setup_all_store_settings
    Spree::Config.stock.allocator_class = 'Spree::Stock::Allocator::AlwaysInStock'
    Spree::Config.stock.estimator_class = 'Spree::Stock::EstimatorForAll'
    ::Spree::StockLocation.default
    find_or_create(:shipping_method_ups, :name)
    find_or_create(:shipping_method_ups_fast, :name)
    find_or_create(:shipping_method_fedex, :name)

    find_or_create(:payment_method_paypal, :name)
    find_or_create(:payment_method_credit_card, :name)
    find_or_create(:payment_method_apple_pay, :name)
    find_or_create(:payment_method_google_pay, :name)

    find_or_create(:basic_tax_rate, :name)
    find_or_create(:zone_member_country, :zoneable_type)
  end
end