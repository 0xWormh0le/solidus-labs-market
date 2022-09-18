::Spree::ShippingMethod.class_eval do
  include ::Spree::StoreUserRelation
  belongs_to :store, class_name:'Spree::Store'


end