::Spree::Country.class_eval do

  def self.united_states
    @@united_states ||= where(iso:'US').first
  end

end