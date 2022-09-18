class CreateRelatedOptionTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_related_option_types do |t|
      t.string :record_type, limit: 128, null: false
      t.integer :record_id, null: false
      t.integer :option_type_id, null: false
      t.integer :position, default: 1
    end
    add_index :spree_related_option_types, [:record_type, :record_id]
    add_index :spree_related_option_types, :position

    categories_taxonomy = ::Spree::Taxonomy.find_or_create_by!(name:'Categories')

    {
      'Clothing' => ['Color', 'Clothing Size'],
      'Baby Clothing' => ['Color', 'Clothing Size'],
      'Girls Clothing' => ['Color', 'Clothing Size'],
      "Girls' Clothing" => ['Color', 'Clothing Size'],
      'Boys Clothing' => ['Color', 'Clothing Size'],
      "Boys' Clothing" => ['Color', 'Clothing Size'],
      "Women's Clothing" => ['Color', 'Clothing Size'],
      "Men's Clothing" => ['Color', 'Clothing Size'],
      'Clothing' => ['Color', 'Clothing Size'],

      'Shoes' => ['Color', 'Shoe Size'],
      'Best Selling Shoes' => ['Color', 'Shoe Size'],
      "Women's Shoes" => ['Color', 'Shoe Size'],
      "Men's Shoes" => ['Color', 'Shoe Size'],
      'Girls Shoes' => ['Color', 'Shoe Size'],
      "Girls' Shoes" => ['Color', 'Shoe Size'],
      'Boys Shoes' => ['Color', 'Shoe Size'],
      "Boys' Shoes" => ['Color', 'Shoe Size'],
      'Sneakers' => ['Color', 'Shoe Size'],
    }.each_pair do|category_name, option_type_names|
      category_taxon = categories_taxonomy.taxons.where('name=?', category_name).first
      if category_taxon
        puts "Category: #{category_taxon.name} (#{category_taxon.id}) => #{option_type_names}"
        option_type_names.each_with_index do|ot_name, position|
          ot = ::Spree::OptionType.where(presentation: ot_name).first
          if ot
            ::Spree::RelatedOptionType.find_or_create_by!(
              record_type: 'Spree::Taxon', record_id: category_taxon.id, option_type_id: ot.id) do|record|
              record.position = position + 1
            end
            puts "  #{position}) #{ot.presentation} (#{ot.id})"
          end
        end
      end
    end
  end
end
