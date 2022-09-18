FactoryBot.define do
  factory :products, class: Spree::Product do
    trait :basic_shipping_and_tax_category do
      shipping_category_id { (Spree::ShippingCategory.default || create(:shipping_category)).id }
      tax_category_id { (Spree::TaxCategory.default || find_or_create(:tax_category,:name)).id }
    end

    factory :basic_product, aliases: [:home_product], traits: [:basic_shipping_and_tax_category] do
      name {'12 in. Pre-Seasoned Cast Iron Skillet'}
      description {"Pre-seasoned skillet distributes heat evenly\r\nMeasures 12 in. D x 2.25 in. H\r\nSuitable for indoor or outdoor cooking"}
      price {13}
      cost_price {10}
      cost_currency {'USD'}
      sku {'UTENSILS350'}
      height {'12 in'}
      width {'12 in'}
      depth {'2 in'}
      weight {'2 lbs'}
      taxon_ids { find_or_create(:home_taxon,:name).id.to_s }
      option_type_ids {  }
      meta_title {'Cast Iron Skillet'}
      meta_keywords {'cast iron skillet'}
      meta_description {'Pre-seasoned skillet distributes heat evenly'}
    end

    factory :art_craft_product, aliases: [:no_price_product], traits: [:basic_shipping_and_tax_category] do
      name {'Personally Painted Color of Angel'}
      description {'Painted in water-color, in poster size'}
      taxon_ids { find_or_create(:home_taxon,:name).id.to_s }
      option_type_ids {  }
    end

    factory :shirt_product, aliases: [:clothes_product], traits: [:basic_shipping_and_tax_category] do
      name {'Silk Dress Shirt For Men'}
      description {"100% Silk in various colors"}
      price {35}
      cost_price {25}
      cost_currency {'USD'}
      taxon_ids { find_or_create(:mens_clothing_category_taxon,:name).id.to_s }
      option_type_ids {  }
    end
  end

  factory :assets, class: Spree::Asset do
    factory :images, class: Spree::Image do
      factory :local_image_file, aliases: [:sample_markers_image] do
        attachment { File.new( File.join(Rails.root, 'public/assets/sample/color_markers-f66e30f4c5033dd7202c8014c77ea2449aee6ab7b39fc05ab3dc75c410dfd4b4.jpg') ) }
      end
    end
  end

end