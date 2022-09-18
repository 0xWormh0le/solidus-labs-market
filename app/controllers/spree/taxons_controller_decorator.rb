##
# Partial override of original Spree::ProductsController.  Not necessary to rewrite whole
# class when most of codes are about the same.
module Spree
  TaxonsController.class_eval do

    def show
      @searcher = build_searcher(params.merge(taxon: @taxon.id, include_images: true))
      @variants = @searcher.retrieve_products
      @taxonomies = Spree::Taxonomy.includes(root: :children)

      respond_to do|format|
        format.html { render 'spree/taxons/show_customized' }
      end
    end

    def show_customized
      @searcher = build_searcher(params.merge(taxon: @taxon.id, include_images: true))
      @products = @searcher.retrieve_products
      logger.info "| products #{@products.class}: #{@products.to_a}"
      logger.info "|   count =  #{@variants.count}, empty? #{@products.empty?}"
      @taxonomies = Spree::Taxonomy.includes(root: :children)
    end

  end
end
