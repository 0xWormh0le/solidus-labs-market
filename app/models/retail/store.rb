class Retail::Store < ::RetailScraperRecord
  self.table_name = 'retail_stores'

  validates_presence_of :retail_site_store_id, :retail_site_id, :store_url

  belongs_to :retail_site, class_name: 'Retail::Site', foreign_key: 'retail_site_id'

  has_many :migrations, class_name: 'Retail::StoreToSpreeUser', foreign_key: 'retail_store_id'
  has_many :spree_users, class_name: 'Spree::User', through: :migrations

  ##
  # Find the make the mapping of StoreToSpreeUser to Spree::User and Spree::Store.
  # @return <Spree::User> w/ its Spree::Store created.
  def setup_spree_user_and_store!
    store_to_spree_user = ::Retail::StoreToSpreeUser.where(retail_store_id: id).first
    spree_user = store_to_spree_user.try(:spree_user)
    unless spree_user
      spree_user = ::Spree::User.create(
        email: "#{retail_site_store_id}@shopp.com", login: retail_site_store_id,
        username: retail_site_store_id, country: 'United States', country_code: 'US',
        password: 'grabbedseller'
      )
    end
    spree_user.store ||= spree_user.create_store!

    store_to_spree_user ||= ::Retail::StoreToSpreeUser.create(
      retail_store_id: id, spree_user_id: spree_user.id)
    spree_user
  end

end