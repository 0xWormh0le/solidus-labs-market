class RenameToGeneralColor < ActiveRecord::Migration[5.2]
  def change
    color_option_type = ::Spree::OptionType.where(presentation:'color').first
    color_option_type.update(name:'General Color', presentation:'Color')
  end
end
