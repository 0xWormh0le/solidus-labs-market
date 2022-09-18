module Spree
  class RelatedOptionType < Spree::Base

    belongs_to :option_type, class_name: 'Spree::OptionType'

    default_scope -> { order(:position) }

    def record
      @record ||= record_type.constantize.find(record_id)
    end

    ##
    # Extends beyond just option_type association, for record_type like
    # category Spree::Taxon, find closest by level (low to high).
    #
    # @return <list of Spree::OptionType>
    def self.closest_option_types(record_type, record_id)
      option_type_ids = []
      if record_type == 'Spree::Taxon' &&
        (record = record_type.constantize.find(record_id)).try(:permalink).try(:start_with?, 'categories')

        # Could not use .where(.... record_id: category_taxon_ids) because diff category levels maybe diff
        record.categories_in_path.reverse.each do|category_taxon|
          break if option_type_ids && option_type_ids.size > 0
          option_type_ids = self.where(record_type: record_type, record_id: category_taxon.id).collect(&:option_type_id)
        end
      else
        option_type_ids = self.where(record_type: record_type, record_id: record_id).collect(&:option_type_id)
      end
      ::Spree::OptionType.where(id: option_type_ids).includes(:option_values)
    end

    def self.closest_option_types_to(record)
      closest_option_types(record.class.to_s, record.id)
    end

  end
end