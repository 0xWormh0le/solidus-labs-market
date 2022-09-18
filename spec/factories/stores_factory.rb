FactoryBot.define do
  factory :store, class: Spree::Store do

    factory :basic_store, aliases: [:sample_store, :clothing_store] do
      name { 'Sample Clothing Store' }
      url { 'localhost' }
      mail_from_address { 'sample_clothing_store@me.com' }
      code { 'stores/sample_clothing_store' }
    end
  end

  factory :payment_method, class: Spree::PaymentMethod do
    active { true }
    available_to_users { true }
    before :create do
      self.description ||= "Pay with #{name}"
      self.position = Spree::PaymentMethod.where(available_to_users: true).count + 1
    end

    factory :payment_method_paypal, class: Spree::PaymentMethod::PayPal do
      name { 'PayPal' }
    end
    factory :payment_method_credit_card, class: Spree::PaymentMethod::CreditCard do
      name { 'Credit Card, Visa/MasterCard' }
      description { 'Pay with credit cards like Visa or MasterCard' }
    end
    factory :payment_method_apple_pay, class: Spree::PaymentMethod::ApplePay do
      name { 'ApplePay' }
    end
    factory :payment_method_google_pay, class: Spree::PaymentMethod::GooglePay do
      name { 'GooglePay' }
    end
  end

  factory :shipping_category, class: Spree::ShippingCategory do
    factory :default_shipping_category do
      name {'Default'}
    end
  end

  factory :shipping_method, class: Spree::ShippingMethod do
    tax_category_id { find_or_create(:default_tax_category, :name).id }
    available_to_all { true }
    available_to_users { true }
    shipping_categories { [ find_or_create(:default_shipping_category, :name) ] }
    calculator { find_or_create(:calculator_default_tax, :type) }

    factory :basic_shipping_method, aliases:
      [:shipping_method_two_to_three_days, :shipping_method_three_days, :shipping_method_ups] do
      name { 'UPS Ground 2-3 Days' }
    end
    factory :shipping_method_one_day, aliases: [:shipping_method_ups_fast] do
      name { 'UPS Ground 1 Day' }
    end
    factory :shipping_method_fedex, aliases: [:shipping_method_air] do
      name { 'Fedex Air 2 Days' }
    end
  end

  factory :tax_category, class: Spree::TaxCategory do
    factory :default_tax_category do
      name { 'Default' }
      is_default { true }
    end
  end

  factory :tax_rate, class: Spree::TaxRate do
    factory :basic_tax_rate, aliases: [:tax_rate_north_america] do
      amount { 0.5 }
      zone_id { find_or_create(:zone_north_america, :name).id }
      included_in_price { false }
      name { 'North America '}
      show_rate_in_label { true }
      calculator { find_or_create(:calcultor, :type) }
      after :create do
        calculator.update(calculable_type: self.class.to_s, calculable_id: id)
      end
    end
  end

  factory :calcultor, class: Spree::Calculator do
    type { 'Spree::Calculator' }
    factory :calculator_default_tax, class: Spree::Calculator::DefaultTax do
      calculable_type { 'Spree::TaxRate' }
      calculable_id { find_or_create(:basic_tax_rate, :name).id }
    end
  end

  factory :zone, class: Spree::Zone do
    factory :zone_north_america, aliases: [:basic_zone] do
      name { 'North America' }
      description { 'USA + Canada' }
      # zone_members_count { 1 }
    end
  end

  factory :zone_member, class: Spree::ZoneMember do
    factory :zone_member_country do
      zoneable_type { 'Spree::Country' }
      zoneable_id { find_or_create(:country_usa, :name).id }
      zone_id { find_or_create(:basic_zone, :name).id }
    end
  end

end
