require 'shared/form_action_helper'
require 'rack/test'

module ProductsSpecHelper
  extend ActiveSupport::Concern
  extend FormActionHelper

  def create_retail_product(product_factory_key, image_urls = [], properties = {})
    product = create(product_factory_key)
    product.product_photos = image_urls.collect do|url|
      p = ::Retail::ProductPhoto.create(retail_product_id: product.id, url: url)
      p.remote_image_url = url
      p.save
      p
    end
    expect(product.site_category).not_to be_nil
    expect(product.site_category.name).to eq(product.category_names.last)

    product
  end

  def cleanup_retail_products
    ::Retail::Product.all.each(&:destroy)
  end

  ###########################################

  def setup_all_for_posting_products
    create(:level_thee_other_site_category)
    Category.find_or_create_categories_taxon
    setup_locale_records
    setup_category_taxons( [:clothing_category_taxon, :level_two_category_taxon, :level_three_category_taxon] )
    setup_site_categories('ioffer', [:level_one_site_category, :level_two_site_category, :level_three_site_category], true )
    setup_option_types_and_values
  end

  def setup_locale_records
    [:country_us, :country_jp, :country_cn, :country_gb, :country_fr].each do|factory_key|
      find_or_create(factory_key, :iso)
    end
  end

  # @category_taxon_factory_keys <Array of symbols> list of factory keys that represent a path of multiple levels.
  def setup_category_taxons(category_taxon_factory_keys)
    @categories_taxon = ::Spree::CategoryTaxon.find_or_create_categories_taxon
    current_node = @categories_taxon
    @category_taxons = category_taxon_factory_keys.collect do|factory_key|
      t =  find_or_create(factory_key, :name) do|new_record|
        new_record.parent_id = current_node.id
      end
      t.move_to_child_of( current_node )
      current_node = t
    end
  end

  ##
  # @site_category_factory_keys <Array of symbols> list of factory keys that represent a path of multiple levels.
  def setup_site_categories(site_name, site_category_factory_keys, mapping_to_category_taxons = true)
    current_node = ::SiteCategory.root_for(site_name)
    categories_taxon = ::Spree::CategoryTaxon.find_or_create_categories_taxon.children.try(:first)
    @site_categories = []
    site_category_factory_keys.each do|factory_key|
      t = create(factory_key, site_name: site_name,
        mapped_taxon_id: mapping_to_category_taxons ? categories_taxon.try(:id) : nil)
      categories_taxon = categories_taxon.children.first if mapping_to_category_taxons && categories_taxon
      t.move_to_child_of( current_node )
      current_node = t
      @site_categories << t
    end
    @site_categories
  end

  ##
  # Basic Spree::OptionType and OptionValue
  def setup_option_types_and_values
    if ::Spree::OptionType.count.zero?
      option_type_color = create(:option_type_color)
      option_type_size = create(:option_type_size)
      option_type_material = create(:option_type_material)
      %w|white black grey red|.each{|_color| create("option_value_#{_color}".to_sym, option_type: option_type_color) }
      %w|xs s m l xl|.each{|_size| create("option_value_#{_size}".to_sym, option_type: option_type_size) }
      %w|cotton silk metal aluminum|.each{|_m| create("option_value_#{_m}".to_sym, option_type: option_type_material) }
    end
    position = 1
    ::Spree::OptionType.where(name: %w|color size|).each do|option_type|
      @category_taxons.each do|ct|
        ::Spree::RelatedOptionType.find_or_create_by!(
          record_type:'Spree::Taxon', record_id: ct.id, option_type_id: option_type.id) do|record|
          record.position = position
        end
      end
      position += 1
    end
  end

  #################################
  # Capybara

  def fill_into_product_form(product_attr)
    product_attr.each_pair do|k, v|
      next if v.nil?
      begin
        if v.is_a?(Array)
          v.each do|sub_v|
            if sub_v.is_a?(Hash)
              sub_v.each_pair do|sub_v_k, sub_v_v|
                xpath_field = find(:xpath, "//*[@name='product[#{k}][]#{sub_v_k}']")
                if sub_v_k.to_s == 'currency'
                  xpath_field.select(sub_v_v)
                else
                  xpath_field.set(sub_v_v)
                end
              end
            end
          end
        else
          find(:xpath, "//*[@name='product[#{k}]']").set(v )
        end
      rescue Capybara::ElementNotFound
        puts "** Cannot find product field #{k}"
      end
    end
  end

  # @sample_image_path <File or IO> for uploading image
  # @options The options that's passed onto check_product_against.
  #   :auto_ensure_available
  # @return <Spree::Product>
  def post_product_via_pages(user, product_key, extra_attributes = {}, sample_image_path = nil, options = {})
    auto_ensure_available = options[:auto_ensure_available]
    auto_ensure_available ||= true
    auto_ensure_user_id = options[:auto_ensure_available]
    auto_ensure_user_id ||= true

    product_attr = attributes_for(product_key).merge(extra_attributes)
    visit new_admin_product_path(form:'form_in_one')
    expect(page.driver.status_code).to eq 200

    fill_into_form(['product', product_attr] )
    if sample_image_path
      find_all(:xpath, "//input[@name='product[uploaded_images][][attachment]']").last.attach_file(sample_image_path)
    end
    click_on('Create')

    product = ::Spree::Product.where(user_id: user.id).last
    expect(product).not_to be_nil
    expect(product.master).not_to be_nil
    if product_attr[:taxon_ids].present?
      current_taxon_ids = product.taxons.collect(&:id)
      product_attr[:taxon_ids].split(',').each do|_tid|
        expect(current_taxon_ids).to include(_tid.to_i )
      end
    end
    if (images = other_attributes[:images] || other_attributes[:uploaded_images] ).present?
      expect(product.gallery.images.size).to eq(images.size) if images
    end
    expect(product.name).to eq(product_attr[:name])
    expect(product.description[0,20] ).to eq(product_attr[:description][0,20] )
    if product.price.to_f > 0.0
      master_price = other_attributes[:price]
      if (price_attr = other_attributes[:price_attributes] ).present?
        price_attr.each do|price_h|
          next unless price_h[:amount]
          if price_h[:currency].blank? || price_h[:currency] ==  Spree::Config.default_pricing_options.desired_attributes[:currency]
            puts "  Assign this as master_price #{price_h}" if master_price.nil?
            master_price ||= price_h[:amount]
          else
            puts "  Got price of #{price_h} ?"
            expect( product.prices.where(currency: price_h[:currency], amount: price_h[:amount]).first ).not_to be_nil
          end
        end
      end
      expect(product.price).to eq master_price
    end

    product.available_on = Time.now if auto_ensure_available && product.available_on.nil?
    if auto_ensure_user_id
      product.user_id = user.id
      product.save

      product.master.user ||= product.user
      product.master.save
    end
    binding.pry # TODO: debug
    visit product_path(product)
    expect(page.driver.status_code).to eq 200

    product
  end

  # @other_attributes
  #   :images = Provide image paths like { images:[ '/shoppn/test.jpg'  ]}
  # @options The options that's passed onto check_product_against.
  def post_product_via_requests(user, product_key, other_attributes = {}, options = {})
    product_attr = attributes_for(product_key)
    images = other_attributes.delete(:images) || []
    uploaded_images = []
    images.each do|sample_image_path|
      mime_type = "image/#{sample_image_path.match(/\.([a-z]{2,3})\Z/).try(:[], 1) || 'jpg'}"
      image_file = fixture_file_upload(sample_image_path, mime_type)
        # ActionDispatch::Http::UploadedFile.new(
        # filename: sample_image_path.split('/').last, content_type: mime_type,
        # tempfile: File.open(sample_image_path) )
      uploaded_images << {attachment: image_file }
      binding.pry # TODO: debug
    end
    product_attr.merge!(uploaded_images: uploaded_images ) if uploaded_images.size > 0
    product_attr.merge!(other_attributes)

    post admin_products_path(product: product_attr)

    product = check_product_against(user, product_key, other_attributes, options)

    product
  end

  private

  ##
  # @options
  #   :auto_ensure_available <Boolean> default true; somehow form submission has product created but
  #     available_on stays nil.  Never see such behavior in real run.
  #   :auto_ensure_user_id <Boolean> default true; somehow product create cannot set user_id
  #
  def check_product_against(user, product_key, other_attributes = {}, options = {})
    auto_ensure_available = options[:auto_ensure_available]
    auto_ensure_available ||= true
    auto_ensure_user_id = options[:auto_ensure_available]
    auto_ensure_user_id ||= true

    product_attr = attributes_for(product_key)
    product = ::Spree::Product.where(user_id: user.id).last
    expect(product).not_to be_nil
    expect(product.master).not_to be_nil

    if product_attr[:taxon_ids].present?
      current_taxon_ids = product.taxons.collect(&:id)
      product_attr[:taxon_ids].split(',').each do|_tid|
        expect(current_taxon_ids).to include(_tid.to_i )
      end
    end
    if (images = other_attributes[:images] || other_attributes[:uploaded_images] ).present?
      expect(product.gallery.images.size).to eq(images.size) if images
    end
    expect(product.name).to eq(product_attr[:name])
    expect(product.description[0,20] ).to eq(product_attr[:description][0,20] )
    if product.price.to_f > 0.0
      default_currency_price = nil
      if (price_attr = other_attributes[:price_attributes] ).present?
        price_attr.each do|price_h|
          next unless price_h[:amount]
          if price_h[:currency].blank? || price_h[:currency] ==  Spree::Config.default_pricing_options.desired_attributes[:currency]
            default_currency_price ||= price_h[:amount]
          else
            puts "  Got price of #{price_h} ?"
            expect( product.prices.where(currency: price_h[:currency], amount: price_h[:amount]).first ).not_to be_nil
          end
        end
      end
      # master price still overrides
      expect(product.price).to eq default_currency_price if product_attr[:price].to_f.zero?
    end

    product.available_on = Time.now if auto_ensure_available && product.available_on.nil?
    if auto_ensure_user_id
      product.user_id = user.id
      product.save

      product.master.user ||= product.user
      product.master.save
    end

    visit product_path(product)
    expect(page.driver.status_code).to eq 200

    product
  end
end