::Spree::StockLocation.class_eval do
  def self.default
    self.find_or_create_by!(supplier_id: nil) do|o|
      o.name = 'Everywhere'
      o.backorderable_default = true
      o.propagate_all_variants = true
      o.restock_inventory = true
      o.fulfillable = true
      o.check_stock_on_transfer = true
    end
  end
end