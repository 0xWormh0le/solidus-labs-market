# frozen_string_literal: true

module Spree
  module Stock
    module Allocator
      class AlwaysInStock < Spree::Stock::Allocator::OnHandFirst
        def allocate_inventory(desired)
          list = super(desired)
          list[2] = []
          list
        end

      end
    end
  end
end
