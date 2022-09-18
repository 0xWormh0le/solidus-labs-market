class AddUserIdToSpreeOptionValues < ActiveRecord::Migration[5.2]
  def up
    add_column :spree_option_values, :user_id, :integer
    add_index :spree_option_values, :user_id
  end

  def down
    remove_column :spree_option_values, :user_id
  end
end
