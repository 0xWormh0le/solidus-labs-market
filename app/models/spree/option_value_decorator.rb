module Spree
  OptionValue.class_eval do

    attr_accessor :variant_ids

    belongs_to :user, class_name: 'Spree::User', foreign_key: :user_id

    scope :with_names, lambda {|option_type_names|
        joins(:option_type).where("#{Spree::OptionType.table_name}.name IN (?)", option_type_names ) }
    scope :single_names, -> { where("name NOT LIKE '%/%' AND name NOT LIKE '% %'") }
    scope :multi_word_names, -> { where("name LIKE '%/%' OR name LIKE '% %'") }
    scope :for_public, -> { where(user_id: nil) }

    # cancan.accessible_by is different
    scope :manageable_by, lambda {|user_id| joins(:option_type).where('user_id IS NULL OR user_id=?', user_id) }

    def self.accessible_by(ability, action = :index)
      self.manageable_by(ability.user.try(:id) )
    end

    def option_type_name
      option_type.try(:name)
    end

    def option_type_presentation
      option_type.try(:presentation)
    end
  end
end