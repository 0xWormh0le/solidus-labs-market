require 'rails_helper'
require 'shared/session_helper'
require 'shared/products_spec_helper'
require 'shared/users_spec_helper'

include SessionHelper
include ProductsSpecHelper
include UsersSpecHelper
# include ::Spree::Api::TestingSupport::Helpers # doesn't work

RSpec.describe ::Spree::Api::OptionValuesController  do
  before(:all) do
    setup_all_for_posting_products
    Capybara.ignore_hidden_elements = false
  end

  let :option_type do
    ::Spree::OptionType.find_or_create_by!(presentation: 'Color') do|record|
      record.name = 'General Color'
      record.position = 1
    end
  end

  context 'Authorize Access' do
    it 'In Model Level' do
      ::Spree::User.fetch_admin
      user1 = find_or_create(:basic_user, :username) {|u| u.password = 'test1234' }
      user2 = find_or_create(:seller, :username) {|u| u.password = 'test1234' }

      option_value = option_type.option_values.create(name:'Bloody Red', presentation:'Bloody Red', user_id: user1.id)
      ability1 = ::Spree::Ability.new(user1)
      ability2 = ::Spree::Ability.new(user2)

      [ability1, ability2].each{|a| expect(a.can?(:manage, option_type) ).to be_falsey  }
      expect( ability1.can?(:manage, option_value ) ).to be_truthy
      expect( ability2.can?(:manage, option_value ) ).to be_falsey
    end

    it 'Custom Option Value In Controller Level' do
      admin = ::Spree::User.fetch_admin
      admin_ability = ::Spree::Ability.new(admin)
      user_attr1 = attributes_for(:basic_user)
      user_attr2 = attributes_for(:seller)

      option_value_attr = { option_type_id: option_type.id, name: 'silver / gold',
        presentation: 'Silver / Gold', extra_value: '#eeeeee,#ffcc00' }

      user1 = sign_up_with(user_attr1[:email], 'test1234', user_attr1[:username], user_attr1[:display_name] )
      ability1 = ::Spree::Ability.new(user1)
      stub_authentication_for!(user1)

      visit api_option_type_option_values_path(option_type_id: option_type.id, format:'json')
      expect(page.driver.status_code).to eq 200

      post api_option_values_path(format:'json', option_type_id: option_type.id, option_value: option_value_attr )

      last_option_value = option_type.option_values.reload.last
      expect(last_option_value.user_id).to eq user1.id
      expect( ability1.can?(:manage, last_option_value) ).to be_truthy
      expect( admin_ability.can?(:manage, last_option_value) ).to be_truthy

      visit api_option_type_option_values_path(option_type_id: option_type.id, format:'json')
      json_list = JSON.parse(page.driver.response.body)
      expect(json_list.is_a?(Array) ).to be_truthy
      matching_json_entry = json_list.find{|j| j['name'] == option_value_attr[:name] }
      expect( matching_json_entry ).not_to be_nil
      expect(matching_json_entry['presentation']).to eq option_value_attr[:presentation]
      expect(matching_json_entry['extra_value']).to eq option_value_attr[:extra_value] if option_value_attr[:extra_value]

      taxon = @category_taxons.try(:first) || ::Spree::CategoryTaxon.find_or_create_categories_taxon
      visit related_option_types_path(format:'json', record_type:'taxon', record_id: taxon.id )
      taxons_json = JSON.parse(page.driver.response.body)
      color_json = taxons_json.find{|j| j['name'] == option_type.name }
      expect(color_json).not_to be_nil
      color_values = color_json['option_values']
      expect(color_values.present?).to be_truthy
      custom_color = color_values.find{|v| v['name'] == option_value_attr[:name] }
      expect(custom_color).not_to be_nil

      visit logout_path

      puts 'Another user --------------------------'
      user2 = sign_up_with(user_attr2[:email], 'test1234', user_attr2[:username], user_attr2[:display_name] )
      ability2 = ::Spree::Ability.new(user2)
      stub_authentication_for!(user2)

      expect( ability2.can?(:manage, last_option_value) ).to be_falsey

      visit api_option_type_option_values_path(option_type_id: option_type.id, format:'json')
      json_list2 = JSON.parse(page.driver.response.body)
      expect(json_list2.is_a?(Array) ).to be_truthy
      matching_json_entry2 = json_list2.find{|j| j['name'] == option_value_attr[:name] }
      expect(matching_json_entry2).to be_nil

      put api_option_value_path(last_option_value, format:'json', option_value: option_value_attr.merge(name:'No name') )
      expect(page.driver.response.status).not_to eq 200
      last_option_value.reload
      expect(last_option_value.name).to eq option_value_attr[:name]
    end
  end # describe
end