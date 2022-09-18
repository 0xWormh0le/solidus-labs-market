module Spree
  module ProductActions
    extend ActiveSupport::Concern

    require 'open-uri'

    # Changed version of Spree::ProductDuplicator#duplicate
    def build_clone(&block)
      draft = self.dup.tap do |new_product|
        new_product.taxons = self.taxons
        new_product.created_at = nil
        new_product.deleted_at = nil
        new_product.updated_at = nil
        new_product.product_properties = self.reset_properties
        # new_product.master = duplicate_master
        new_product.price = self.price
        new_product.sku = '' # "COPY OF #{self.sku}" if self.sku.present? && !self.sku.start_with?('COPY OF ')
      end

      draft.option_types = self.option_types
      draft.master_product_id = self.master_product_id || self.id
      draft.find_or_build_master
      draft.copy_taxons_from(self)

      yield draft if block_given?
      draft
    end

    def copy_taxons_from(other_product)
      other_product.classifications.includes(:taxon).each do|c|
        new_c = ::Spree::Classification.new(product_id: self.id, taxon_id: c.taxon_id, position: c.position)
        self.classifications << new_c
        self.taxons << c.taxon if c.taxon # immediate ref
      end
    end

    # @return <Array of Spree::Image>
    def copy_images_from_retail_product!(retail_product)
      self.find_or_build_master.images = retail_product.product_photos.collect do|product_photo|
        copy_from_retail_product_photo!(product_photo)
      end.compact
    end

    def copy_variants_from!(other_product)
      other_product.variants_including_master.each do|v|
        v.option_values.each do|option_value|
          if v.is_master
            new_ovv = ::Spree::OptionValuesVariant.find_or_create_by(variant_id: self.master.id, option_value_id: option_value.id)
            self.master.option_values_variants.reload
            new_ovv
          else
            self.variants.create(option_value_ids: [option_value.id], price: master.price)
          end
        end
      end
    end

    ##
    # Copying images from master_product.
    def copy_from_master!
      if master_product_id && master_product
        master_variant = find_or_build_master
        master_product.images.each do|image|
          new_image = image.dup
          new_image.assign_attributes(attachment: image.attachment.clone)
          new_image.viewable_type = 'Spree::Variant'
          new_image.viewable_id = master_variant.id
          new_image.save
        end
      end
    end

    def process_uploaded_images
      if uploaded_images.present?
        self.image_alts ||= []
        self.image_viewable_ids ||= []
        cur_position = (self.gallery.images.collect(&:position).max || 0) + 1
        # logger.info "| Got uploaded_images:# #{uploaded_images}"
        uploaded_images.each_with_index do|uploaded_image, index|
          image_attr = uploaded_image.is_a?(::ActionDispatch::Http::UploadedFile) ?
              { alt: image_alts[index], attachment: uploaded_image } :
              uploaded_image
          viewable_id = image_attr[:viewable_id] || image_viewable_ids[index]
          image_attr[:viewable_id] = viewable_id.to_i if viewable_id # ensure it's Integer
          image_attr[:viewable_id] ||= self.master.try(:id)
          image_attr[:viewable_type] ||= 'Spree::Variant'
          image_attr[:position] = cur_position
          img = ::Spree::Image.create(image_attr)
          logger.warn "    valid? #{img.valid?}: #{img.errors.full_messages}" unless img.valid? || img.id
          cur_position += 1
        end
      end
    end

    def set_update_attributes
      self.has_sorting_rank_changes = (transaction_count_changed? || gross_merchandise_sales_changed?)
    end

    def update_variants!(force_to_update = false, &block)
      if force_to_update || has_sorting_rank_changes
        self.variants_including_master.each do|v|
          yield v if block_given?
          v.update_sorting_rank!
        end
      end
    end

    # @retail_product_or_site_category <either SiteCategory or Retail::Product>
    def create_categories_taxon!(retail_product_or_site_category)
      site_category = retail_product_or_site_category.is_a?(::SiteCategory) ?
          retail_product_or_site_category : retail_product_or_site_category.leaf_site_category
      if site_category.try(:mapped_taxon_id)
        ::Spree::Classification.find_or_create_by(product_id: id, taxon_id: site_category.mapped_taxon_id) do|c|
          c.position = 1
        end
      end
    end

    ##
    # Some specs are simply existing option types such as color, as could represent a variant while
    # still created as properties w/ joined values as backup of the original names and values.
    def copy_product_specs_from_retail_product!(retail_product, create_new_option_value = false)
      copy_from_retail_product_specs!(retail_product.product_specs, create_new_option_value)
    end

    ##
    # Saves the specs and variants.
    def copy_from_retail_product_specs!(product_specs, create_new_option_value = false)
      build_from_retail_product_specs(product_specs, :create, create_new_option_value)
    end

    ##
    # Some specs are simply existing option types such as color, as could represent a variant while
    # still created as properties w/ joined values as backup of the original names and values.
    # @product_specs <Collection of Retail::ProductSpec>
    # @new_or_create_method <Symbol> whether :new for temporary objects or :create for saving in DB.
    #
    def build_from_retail_product_specs(product_specs, new_or_create_method, create_new_option_value = false)

      group = product_specs.group_by(&:name)
      option_types = ::Spree::OptionType.where('name IN (?) OR presentation IN (?)', group.keys, group.keys).all
      option_types_group = option_types.group_by{|ot| ot.presentation.downcase }
      option_values_group = Spree::OptionValue.where(option_type_id: option_types.collect(&:id)).group_by{|ov| ov.option_type_presentation.downcase }
      variant_ids = self.variants_including_master.to_a.collect(&:id)
      group.each_pair do|spec_name, spec_list|
        if new_or_create_method == :create
          self.set_property_with_list(spec_name, spec_list)
        else
          self.properties << ::Spree::Property.new(name: spec_name, presentation: spec_list.join(',') )
        end
        # Try to create variants for this spec name and values
        option_values = option_values_group[spec_name.downcase] || []
        if create_new_option_value || option_values
          option_type = option_types_group[spec_name.downcase].try(:first) || option_values.first.try(:option_type)
          next if option_type.nil?

          product_option_type = self.product_option_types.find{|ot| ot.id == option_type.id }
          self.product_option_types.send(new_or_create_method, position: self.product_option_types.size + 1, option_type_id: option_type.id) if product_option_type.nil?

          spec_list.each do|spec|
            option_value = option_values.find{|var| var.presentation.downcase == spec.value_1.downcase }
            is_new_option_value = false
            unless option_value
              option_value ||= Spree::OptionValue.send(new_or_create_method, option_type_id: option_type.id,
                                                         position: option_values.size, name: spec.value_1, presentation: spec.value_1)
              option_values << option_value
              is_new_option_value = true
            end
            # see if variant is attached
            if is_new_option_value || Spree::OptionValuesVariant.where(variant_id: variant_ids, option_value_id: option_value.id).count == 0
              new_variant = self.variants.send(new_or_create_method, price: master.price)
              Spree::OptionValuesVariant.send(new_or_create_method, variant_id: new_variant.id, option_value_id: option_value.id)
            end
          end
        end
      end
      self.save if new_or_create_method == :create

    end

    ##
    # @product_photo <Retail::ProductPhoto>
    # @return <Spree::Image> added photo if successfully copied/downloaded
    def copy_from_retail_product_photo!(product_photo_or_url, &block)
      spree_image = nil
      url = product_photo_or_url.is_a?(::Retail::ProductPhoto) ? product_photo_or_url.image_url : product_photo_or_url.to_s
      if url.present?
        if url.start_with?('/') # copy local
          file_path = File.join( ::Retail::ProductPhoto::BASE_PATH, url)
          logger.debug "ProductPhoto.image at #{file_path}, exists? #{File.exists?(file_path)}"
          spree_image = Spree::Image.create(:attachment => File.open(file_path), :viewable => self.find_or_build_master)

        else # download
          open(url) do|image|
            spree_image = Spree::Image.create(:attachment => image, :viewable => self.find_or_build_master)
          end
        end
        yield spree_image if block_given? && spree_image
      end
      spree_image
    rescue Exception => e
      logger.warn "** Spree::Product(#{id}): #{e.message}"
      binding.pry # TODO: debug
      spree_image
    end


    ##
    # Join values into one value within DB limit.
    def set_property_with_list(spec_name, spec_list)
      return if spec_name.blank? || spec_list.blank?
      value_s = build_property_value(spec_list)
      self.set_property(spec_name, value_s) if value_s.present?
    end

    # DB column limit of 100, need to join manually
    def build_property_value(spec_list)
      value_s = ''
      spec_list.uniq.each do|spec|
        if value_s.size + spec.value_1.to_s.size + 1 < 100
          value_s << ' ' unless value_s == ''
          value_s << spec.value_1.to_s
        else
          break
        end
      end
      value_s
    end

    # From Spree::ProductDuplicator
    def reset_properties
      self.product_properties.map do |prop|
        prop.dup.tap do |new_prop|
          new_prop.created_at = nil
          new_prop.updated_at = nil
        end
      end
    end

    def recalculate_view_count!
      total_count = self.variants_including_master.select('id,view_count').collect(&:view_count).sum
      self.update(view_count: total_count) if total_count != view_count
      total_count
    end

    def recalculate_gms!

    end
    alias_method :recalculate_gross_merchandise_sales!, :recalculate_gms!

  end
end