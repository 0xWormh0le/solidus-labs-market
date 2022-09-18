module Scraper::PageParser

  ##
  # @yield <Mechanize::Link> if found
  def collect_index_links(agent, mechanize_page = nil, &block)
    agent.find_index_links(mechanize_page || agent.current_page).each do|link|
      yield link if block_given?
    end
  end

  ##
  # @yield <Mechanize::Link> if founds
  def collect_product_links(agent, mechanize_page = nil, &block)
    agent.find_product_links(mechanize_page || agent.current_page).each do|link|
      yield link if block_given?
    end
  end

  ##
  # @yield <Mechanize::Link> if founds
  def collect_seller_links(agent, mechanize_page = nil, &block)
    agent.find_seller_links(mechanize_page || agent.current_page).each do|link|
      yield link if block_given?
    end
  end

  def parse!(agent, mechanize_page = nil, options = {}, &block)
    agent ||= self.retail_site.scraper
    mechanize_page ||= agent.current_page
    collect_index_links(agent, mechanize_page, &block)

    collect_product_links(agent, mechanize_page, &block)

    if page_type =~ /^detail$/i
      parse_product_detail_page!(agent, mechanize_page) do|product|
        product.reset_assets! if options[:reset_existing_product]
      end
    end
  end

  ##
  # create product and download photos
  # @yield when it's existing product
  def parse_product_detail_page!(agent = nil, mechanize_page = nil, product_attr = {}, &block)
    agent ||= self.retail_site.scraper
    store = ::Retail::Store.find_or_create_retail_store(retail_site_id, agent, mechanize_page || agent.current_page)

    found_product_attr = agent.find_product_attributes(mechanize_page)
    product = ::Retail::Product.where(scraper_page_id: id).last
    if product
      yield product if block_given?

      product.update_attributes(found_product_attr.slice!(:specs, :photos, :store) ) if found_product_attr.size > 0
      unless self.id == product.scraper_page_id
        product.scraper_page_id = self.id
        product.save
      end
    elsif found_product_attr.size > 0
      product_attr.merge! found_product_attr
      if product_attr.size > 0
        product = ::Retail::Product.create(retail_site_id: retail_site_id,
                                           retail_store_id: store.try(:id), scraper_page_id: id,
                                           title: product_attr[:title], description: product_attr[:description],
                                           price: product_attr[:price], categories: product_attr[:categories] || '' )
        .each do|spec|
          spec.retail_product_id = product.id
          spec.save
          BG_LOGGER.debug "  + #{spec}"
        end
      end
    end

    product_specs = product_attr.fetch(:specs, [] )
    product.find_or_create_product_specs!(product_specs) if product

    photos_attr = found_product_attr.fetch(:photos, [])
    if product && product.product_photos.count == 0 && photos_attr
      product.save_product_photos!(photos_attr )
    end
    product
  end

  ##
  # Similar to parse_product_detail_page!, but without saving records.
  # There uses temp_specs instead of product_specs to avoid cached scope records while calling .product_specs.
  def make_product_from_page(agent = nil, mechanize_page)
    agent ||= self.retail_site.scraper

    product_attr = agent.find_product_attributes(mechanize_page)
    product = ::Retail::Product.new
    if product_attr.size > 0
      product = ::Retail::Product.new(retail_site_id: retail_site_id, scraper_page_id: id,
                                        title: product_attr[:title], description: product_attr[:description], price: product_attr[:price] )
      product.temp_specs = product_attr.fetch(:specs, [] )
      product.product_photos = product_attr.fetch(:photos, []).collect do|photo_url|
        photo_obj = ::Retail::ProductPhoto.new(retail_product_id: product.id )
        photo_obj.remote_image_url = photo_url
        photo_obj.url = photo_url
        photo_obj
      end
    end
    product
  end


  ##
  # Source from locally saved file, recall page parsing and update self attributes and links if found.
  def reparse!(agent = nil)
    agent ||= retail_site.scraper
    mechanize_page ||= make_mechanize_page(agent)
    return if mechanize_page.nil?

    self.parse!(agent, mechanize_page) do|link|
      logger.debug '* %40s (%s)' % [link.text.squish, link.href]
      self.class.add_if_needed(link.uri, retail_site_id: retail_site_id, title: link.text.strip) if link.uri
    end
  end

  protected

  ##
  # TODO: method onto to u
  def save_product_specs_for!(product, product_specs_list)
    ActiveSupport::Deprecation.warn('Use product.find_or_create_product_specs instead')

    existing_specs = Set.new( product.product_specs.collect(&:value_for_comparison) )
    product_specs_list.fetch(:specs, [] ).each do|spec|
      unless existing_specs.include?(spec.value_for_comparison)
        spec.retail_product_id = product.id
        spec.save
        BG_LOGGER.debug "  + #{spec}"
        existing_specs << spec.value_for_comparison
      end
    end
  end

  # :retail_product_id, :name, :image, :default_photo, :image_processing, :url
  def save_product_photos_for!(product, photos_list = [] )
    ActiveSupport::Deprecation.warn('Use product.save_product_photos! instead')
    photos_list.each_with_index do|photo_url, idx|
      begin
        photo_obj = ::Retail::ProductPhoto.new(retail_product_id: product.id, default_photo: idx == 0)
        photo_obj.remote_image_url = photo_url
        photo_obj.url = photo_url
        photo_obj.save

        BG_LOGGER.debug "  + #{photo_obj}"

      rescue Exception => photo_e
        BG_LOGGER.warn "** #{photo_e.message} problem DL photo of product(#{product.id}): #{photo_url}"
      end
    end
    BG_LOGGER.info "  > Product(#{product.id}) w/ #{product.product_specs.count} specs, #{product.product_photos.count} photos"
  end

end
