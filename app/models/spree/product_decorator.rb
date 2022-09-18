module Spree
  Product.class_eval do

    include ProductActions

    attr_accessor :has_sorting_rank_changes, :uploaded_images, :image_alts, :image_viewable_ids, :currency, :price_attributes
    accepts_nested_attributes_for :prices, allow_destroy: true

    belongs_to :user, class_name: 'Spree::User'

    has_one :migration, class_name: 'Retail::ProductToSpreeProduct', foreign_key: :spree_product_id
    delegate :retail_product, to: :migration

    belongs_to :master_product, class_name: 'Spree::Product', foreign_key: :master_product_id
    has_many :slave_products, class_name: 'Spree::Product', foreign_key: :master_product_id

    after_create :copy_from_master!
    after_save :process_uploaded_images
    before_update :set_update_attributes
    after_update :update_variants!

    # @return <nested Array of Array of Spree::Taxon> except 'Categories' root taxon.
    def categories
      unless @categories
        @categories = self.taxons.under_categories.collect do |taxon|
          taxon.categories_in_path
        end
      end
      @categories
    end

    def days_available
      available_on ? ((Time.zone.now - available_on) / 1.day.to_f).round.to_i : 0
    end

    alias_method :days_listed, :days_available

    alias_attribute :gms, :gross_merchandise_sales
    alias_attribute :txn_count, :transaction_count

    ##
    # Instead of self.sku, this would check if there's master product for its sku.
    def master_sku
      master_product_id ? master_product.try(:sku) : sku
    end

    ##
    # @return <Hash of Integer(:option_type_id) => Array of Spree::OptionValue, where each contains a set of variant_ids>
    def hash_of_option_type_ids_and_values
      unless @hash_of_option_type_ids_and_values
        option_value_id_to_variant_ids = ActiveSupport::HashWithIndifferentAccess.new
        variants.each do |v|
          v.option_values_variants.select('option_value_id').each do |ovv|
            list = option_value_id_to_variant_ids[ovv.option_value_id] || []
            list << v.id
            option_value_id_to_variant_ids[ovv.option_value_id] = list
          end
        end
        own_option_values = ::Spree::OptionValue.includes(:option_type).
            where(id: option_value_id_to_variant_ids.keys).
            order("#{::Spree::OptionType.table_name}.position").all
        own_option_values.each do |ov|
          ov.variant_ids = option_value_id_to_variant_ids[ov.id]
        end
        @hash_of_option_type_ids_and_values = own_option_values.group_by(&:option_type_id)
      end
      @hash_of_option_type_ids_and_values
    end

    def current_price_attributes
      if self.master
      else
        []
      end
    end

    ##
    # @return <Array of Spree::Price> that aren't set yet
    def available_price_attributes

    end

    ####################################
    # Action methods

    # Create ::Spree::Price from .price_attributes.
    def apply_price_attributes(save_or_not = false)
      if price_attributes.present?
        ids_to_delete = []
        existing_map = master.prices.group_by(&:currency)
        price_attributes.each_with_index do|price_attr, price_idx|
          new_price = ::Spree::Price.new(price_attr)
          if new_price.amount.to_f > 0.0
            if new_price.valid?
              if ( existing_one = existing_map[new_price.currency].try(:first) )
                existing_one.amount = new_price.amount
                existing_one.save if save_or_not
                existing_map.delete(new_price.currency) # duplicate but empty ones would delete
              else
                if new_price.has_default_currency? && self.price.to_f.zero?
                  self.price ||= new_price.amount
                else
                  if save_or_not
                    self.master.prices.create new_price.attributes
                  else
                    self.master.prices << new_price
                  end
                end
              end
            else
              self.errors.add("price_attributes[#{price_idx}]".to_sym, new_price.errors.messages.first)
            end
          else # no amount
            if ( existing_one = existing_map[new_price.currency].try(:first) )
              ids_to_delete << existing_one.id if existing_one.amount.to_f > 0.0 && !existing_one.changed?
            end
          end # new_price.amount
        end

        # Clear away old duplicates or removed
        if save_or_not && ids_to_delete.present?
          ::Spree::Price.where(id: ids_to_delete).delete_all
        end
      end
    end


  end # class_eval
end