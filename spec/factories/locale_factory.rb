FactoryBot.define do
  factory :basic_countries, class: ::Spree::Country do # Spree has in its specs

    factory :default_country, aliases: [:country_us] do # country_usa
      iso_name { 'UNITED STATES'}
      iso { 'US' }
      iso3 { 'USA' }
      name { 'United States of America' }
      numcode { 840 }
      states_required { true }
    end

    factory :country_jp, aliases: [:country_japan] do
      iso_name { 'JAPAN'}
      iso { 'JP' }
      iso3 { 'JPN' }
      name { 'Japan' }
      numcode { 392 }
      states_required { true }
    end

    factory :country_cn, aliases: [:country_china] do
      iso_name { 'CHINA'}
      iso { 'CN' }
      iso3 { 'CHN' }
      name { 'China' }
      numcode { 156 }
      states_required { true }
    end

    factory :country_gb, aliases: [:country_great_britain, :country_uk, :country_united_kingdom] do
      iso_name { 'UNITED KINGDOM' }
      iso { 'GB' }
      iso3 { 'GBR' }
      name {'United Kingdom'}
      numcode { 826 }
      states_required { true }
    end

    factory :country_fr, aliases: [:country_france] do
      iso_name { 'FRANCE' }
      iso { 'FR' }
      iso3 { 'FRA' }
      name {'France'}
      numcode { 250 }
      states_required { true }
    end
  end
end