##
# Partial override of original Spree::ProductsController.  Not necessary to rewrite whole
# class when most of codes are about the same.
module Spree
  ProductsController.class_eval do

    def index
      @searcher = Spree::Core::Search::Base.new(params.merge(include_images: true) ).tap do |searcher|
        searcher.current_user = try_spree_current_user
        searcher.pricing_options = current_pricing_options
      end

      @products = @searcher.retrieve_products
      @taxonomies = Spree::Taxonomy.includes(root: :children)
    end

  end
end
