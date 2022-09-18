module Spree
  Price.class_eval do

    include ::Spree::CurrencyToCountry

    before_save :normalize_country
    after_save :update_variant

    def update_variant
      variant.update_sorting_rank!
    end

    # @return <Money::Currency> could be nil
    def money_currency
      self.class.iso_code_to_currency_map[ currency.try(:upcase) ].try(:first)
    end

    def has_default_currency?
      currency == self.class.default_currency
    end

    ##
    # If country_iso is still nil, would fetch via currency to country ISO mapping.
    def related_country_isos
      self.class::CURRENCY_TO_COUNTRY_ISO_MAP[ currency.try(:upcase).try(:to_sym) ] || []
    end

    def self.iso_code_to_currency_map
      @@iso_code_to_currency_map ||= Spree::Config.available_currencies.group_by(&:iso_code)
    end

    def self.default_currency
      Spree::Config.default_pricing_options.desired_attributes[:currency]
    end

    protected

    def normalize_country
      self.country_iso = nil if country_iso.blank?
    end
  end
end