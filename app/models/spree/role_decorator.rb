::Spree::Role.class_eval do
  def self.admin_role
    self.find_or_create_by!(name: 'admin')
  end
end