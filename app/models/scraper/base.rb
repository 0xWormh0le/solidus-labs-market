##
# Interface for crawling and scraping info from some retailer site.
# Each site should have its own implementation of this.
class Scraper::Base < ::Mechanize

  self.log = Logger.new(STDERR)

  HAS_MULTIPLE_LOCALE_VERSIONS = false
  LOCALES = %w(en-US fr-FR es-ES de-DE nl-NL it-IT pt-BR da-DK el-GR ru-RU sv-SE he-IL pl-PL ar-AR tr-TR ja-JP ko-KR zh-CN)

  def self.scraper_class(site_name)
    begin
      "::Scraper::#{site_name.camelize}".safe_constantize
    rescue
      ::Scraper::Base # does nothing much
    end
  end

  def self.url_of_page(page_or_url)
    case page_or_url
      when ::Mechanize::Page, ::Net::HTTPResponse
        page_or_url.uri.path
      else
        URI(page_or_url.to_s).path
    end
  end

  ##
  # Implement own overriding version to specifically clean things like unnecessary parameters.
  def self.clean_page_url(page_url)
    page_url.to_s
  end


  def self.find_pagination_number(uri_or_url)
    1
  end

  def self.body_of_page(page_or_source)
    case page_or_source
      when ::Mechanize::Page, ::Net::HTTPResponse
        page_or_source.body
      when ::File
        page_or_source.read
      else
        page_or_source.to_s
    end
  end

  ####################################
  # Instance

  def agent
    self
  end

  # @return <String> one of those Scraper::Page::PAGE_TYPES
  def page_type_for(page_or_url)
    'landing'
  end

  # Parses, normalizes and constructs a hash of attributes (matching those in Scraper::Page).
  # @return <Hash of :page_url, :page_uri, :params_in_yaml>
  def parse_link(page_url)

  end

  # @page <::Mechanize::Page>
  def find_index_links(page, &block)
    []
  end

  def find_seller_links(page, &block)
    []
  end

  # @page <::Mechanize::Page>
  def find_product_links(page, &block)
    []
  end

  # @return <Hash>
  def find_product_attributes(page, &block)
    {}
  end

  # @return <Retail::Product>
  def make_product(attributes = {})
  end

  def find_product_photos(page, &block)
    []
  end

  def find_product_specs(page, &block)
    []
  end

  def find_retail_store_attributes(page)
    {}
  end

  # @return <Hash> w/ dynamic pairs of values for categories, such as :name, :category_id, :level
  def find_categories_object(page)
    {}
  end

  def save_cookie_to_scraper_run(scraper_run)
    sio = StringIO.new('', 'r+')
    self.cookie_jar.save(sio)
    scraper_run.update_attributes(cookie: sio.string )
    sio
  end

  def load_cookie_from_scraper_run(scraper_run)
    sio = StringIO.new(scraper_run.cookie || '', 'r')
    self.cookie_jar.clear
    self.cookie_jar.load(sio)
    sio
  end

  ##
  # Assuming some action needed for setting locale/language of content.
  def switch_locale(locale)
  end

  #######################################
  # Overrides


  ##########################3
  # Helper methods


  def basic_strip_of_tags(source)
    source.gsub(/(<\/?\w+[^>]*>)/, '')
  end

  def strip_of_embedded_codes(source)
    source.gsub( /<(script|style)\b.*>.*<\/(script|style)>/, '' )
  end

  def body_text_only(page_or_source)
    basic_strip_of_tags( strip_of_embedded_codes( self.class.body_of_page(page_or_source) ) )
  end

  def find_meta(mechanize_page, meta_name)
    content = nil
    mechanize_page.search('meta').each do|e|
      content = e.attributes['content'].try(:value) if e.attributes['name'].try(:value) =~ /#{meta_name}/i
    end
    content
  end

end
