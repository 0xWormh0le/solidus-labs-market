##
# Similar to ProductUserRelation, this defines ability of user for records that
# have store_id instead of user_id.
module Spree
  module StoreUserRelation

    MANAGEABLE_CLASSES = [
        Spree::ShippingMethod,
        Spree::StorePaymentMethod,
    ]

    def self.included(klass)
      klass.extend ModelClassMethods

      klass.belongs_to :store, class_name:'Spree::Store' unless klass.public_instance_methods.include?(:store)

      klass.delegate :user_id, to: :store
      klass.delegate :user, to: :store
    end

    module ModelClassMethods
      def accessible_by(ability, action = :index)
        ability.user.admin? ?
          where("store_id IS NULL OR store_id=#{ability.user.fetch_store.id}") :
          where(store_id: ability.user.fetch_store.id)
      end
    end

  end
end

::Spree::StoreUserRelation::MANAGEABLE_CLASSES.each do|klass|
  klass.class_eval { include ::Spree::StoreUserRelation }
end