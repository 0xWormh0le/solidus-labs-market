module Spree
  module Stock
    class EstimatorForAll < ::Spree::Stock::Estimator
      # If none, simply create any
      def shipping_rates(package, frontend_only = true)
        rates = super(package, frontend_only)
        if rates.empty?
          shipping_method = ::Spree::ShippingMethod.first
          rate = shipping_method.shipping_rates.new(
              cost: 4.99, shipment: package.shipment )
          tax_rate = Spree::TaxRate.first
          amount = 4.99
          item_tax = Spree::Tax::ItemTax.new(item_id: rate.id,
            label: tax_rate.adjustment_label(amount), tax_rate: tax_rate, amount: amount)
          rate.taxes.new(amount: item_tax.amount, tax_rate: item_tax.tax_rate )
          rates << rate
        end
        rates
      end
    end
  end
end