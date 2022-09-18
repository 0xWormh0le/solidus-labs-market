::Spree::Admin::ShippingMethodsController.class_eval do

  include ::Spree::StoreControllerRelation

  private

  # Override that in backend/app/controllers/spree/admin/resource_controller.rb
  def build_resource
    resource = super
    resource.available_to_users = true
    resource
  end
end