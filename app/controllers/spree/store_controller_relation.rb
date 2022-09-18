##
# Corresponding w/ Spree::StoreUserRelation, this defines the variations of record
# queries and builds.  This basically switches admin-only model to user-based.
module Spree
  module StoreControllerRelation

    # Override that in backend/app/controllers/spree/admin/resource_controller.rb
    def build_resource
      resource = super
      resource.store_id = spree_current_user.fetch_store.id if spree_current_user
      resource
    end
  end
end