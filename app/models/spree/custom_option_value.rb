module Spree
  class CustomOptionValue < Spree::Base
    belongs_to :option_type, class_name: 'Spree::OptionType', inverse_of: :option_values
    acts_as_list scope: :option_type
  end
end