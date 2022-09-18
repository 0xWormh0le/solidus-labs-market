RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

def find_or_create(factory_key, primary_search_attribute, &block)
  new_obj = build(factory_key)
  existing = new_obj.class.where(primary_search_attribute => new_obj.send(primary_search_attribute) ).first
  unless existing
    yield new_obj if block_given?
    new_obj.save
    existing = new_obj
  end
  existing
end