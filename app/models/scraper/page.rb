require 'csv'

class Scraper::Page < ::ApplicationRecord

  include ::Scraper::PageParser

  self.table_name = 'scraper_pages'

  # Full attributes:  page_type, retail_site_id, retail_store_id, title, page_url, url_path, url_params,
  # pagination_number, referrer_page_id, root_referrer_page_id, file_path

  validates_presence_of :retail_site_id, :page_url

  # object_constants :page_type, :landing, :store, :index, :detail
  PAGE_TYPES = %w|LANDING STORE INDEX DETAIL|

  # object_constants :file_status, :not_fetched, :saved
  FILE_STATUSES = %w|NOT_FETCHED SAVED|

  belongs_to :retail_site, class_name: 'Retail::Site'
  belongs_to :retail_store, class_name: 'Retail::Store', optional: true
  belongs_to :referrer_page, class_name: 'Scraper::Page', foreign_key: 'referrer_page_id', optional: true
  alias_method :parent_page, :referrer_page
  has_many :page_requests, class_name: 'Scraper::PageRequest', foreign_key: 'scraper_page_id', dependent: :destroy

  has_many :following_pages, class_name: 'Scraper::Page', foreign_key: 'referrer_page_id'

  has_one :retail_product, class_name: 'Retail::Product', foreign_key: 'scraper_page_id'
  alias_method :product, :retail_product

  delegate :scraper_class, :scraper, :abs_url, :to => :retail_site

  before_save :normalize
  before_destroy :delete_files

  def self.which_site(url, options = {})
    u = url.is_a?(URI::Generic) ? url : URI(url)
    site = nil
    if options[:retail_site_id]
      site = ::Retail::Site.find_via_cache(options[:retail_site_id] )
    end
    site ||= ::Retail::Site.find_matching_site(u.host || site.try(:domain))
    site
  end

  ##
  # If @url does not contain the domain, provide inside options[:domain].
  # @url <URI::Generic or String of some URL>
  # @options <Hash> the attributes of record
  #   :retail_site <Retail::Site> optional; provide this to avoid having to query according to +url+
  def self.find_same_page(url, options = {})
    u = url.is_a?(URI::Generic) ? url : URI(url)
    site = options[:retail_site] || which_site(u, options)
    return nil if site.nil?
    where(retail_site_id: site.id, url_path: u.path, url_params: u.sorted_query(false) ).last
  end

  ##
  # If @uri does not contain the domain, provide inside options[:domain].
  # @uri <URI::Generic>
  # @options <Hash> the attributes for searching or creating the page
  # @return <Scraper::Page> could be nil if no matching site.
  def self.add_if_needed(uri, options = {})
    return nil if uri.nil?
    site = which_site(uri, options)
    return nil if site.nil? || uri.nil?
    p = find_same_page(site.scraper_class.clean_page_url(uri), retail_site_id: site.id)
    if p
      p.update_attributes(options) if options.size > 0
    else
      p = create_from_uri(uri, site, options )
    end
    p
  end

  # @uri <URI::Generic>
  def self.create_from_uri(uri, site = nil, options = {})
    site ||= ::Retail::Site.find_matching_site(uri.host)
    create( retail_site_id: site.id, title: options[:title], page_url: site.scraper_class.clean_page_url(uri),
      referrer_page_id: options[:referrer_page_id], root_referrer_page_id: options[:root_referrer_page_id] )
  end

  def self.base_dir
    File.join( Rails.root, "public/spages_#{Rails.env.downcase}/" )
  end

  ################################
  # Instance

  def abs_page_url
    retail_site.abs_url(page_url)
  end

  def relative_page_url
    URI(retail_site.abs_url(page_url) ).request_uri
  end

  def fix_pagination_number!
    self.pagination_number = self.retail_site.scraper.class.find_pagination_number(page_url.uri)
    self.save
    self.pagination_number
  rescue URI::InvalidURIError
    logger.warn "Invalid URI on #{self}"
  end

  ##
  # For PageRequest to be used to calculate the priority of requests to run on the queue.
  def priority_factor
    case page_type
      when 'detail'
        10
      when 'index'
        pagination_number.to_i <= 10 ? 5 : 3
      else
        2
    end
  end

  ########################################
  # Local file methods

  ##
  # Making of the path with folders that separate pages into grouped folders.
  def page_subfolder
    subfolder_path = ''
    id_s = id.to_s(16)
    0.upto(id_s.size - 1) do|i|
      subfolder_path << '/' if i > 0 && i % 3 == 0
      subfolder_path << id_s[i]
    end
    subfolder_path
  end

  def page_dir
    File.join(self.class.base_dir, page_subfolder )
  end

  def make_file_path(locale = nil)
    actual_file_path = File.join(page_dir, id.to_s + '.html')
    actual_file_path.gsub!(/(\.html)$/, ".#{locale}.html") if locale && locale != 'en-US'
    actual_file_path
  end

  ##
  # Save this to local.
  # @page_object <Mechanize::Page>
  def save_page(page_object, locale = nil, do_update_attributes = true)
    file_path = make_file_path
    actual_file_path = make_file_path(locale)
    `mkdir -p #{page_dir}`
    BG_LOGGER.debug "> saving #{page_url} to #{actual_file_path}"
    begin
      File.open( actual_file_path, "w:#{Encoding::ASCII_8BIT}" ) do|f|
        f.write(page_object.body.encode(Encoding::ASCII_8BIT) )
      end
      self.update_attributes(file_path: file_path, file_status: 'SAVED' ) if do_update_attributes
    rescue IOError
      self.update_attributes(file_path: nil, file_status: 'NOT_FETCHED' ) if do_update_attributes
    end
    actual_file_path
  end

  # For recreating the page object after save.
  # @return <Mechanize::Page> might be nil if cannot read from file_path
  def make_mechanize_page(agent = nil, locale = nil)
    return nil if file_path.blank? || !File.exists?(file_path)
    agent ||= retail_site.scraper
    actual_file_path = (locale.blank? || locale == 'en-US') ? file_path :
      file_path.gsub(/(\.html)$/, ".#{locale}.html")
    File.open(actual_file_path, 'r:UTF-8') do|f|
      ::Mechanize::Page.new( URI( retail_site.abs_url(page_url)), nil, f.read, 200, agent )
    end
  rescue Errno::ENOENT
    nil
  end

  PAGE_FILENAME_REGEX = /(\.[\w]{2,3}\-[\w]{2,3})?\.html$/

  ##
  # @return <Hash locale => URL path>
  def file_versions
    h = {}
    return h unless Dir.exist?(page_dir)
    url_prefix = "/spages_#{Rails.env.downcase}/#{page_subfolder}"
    Dir.entries( page_dir ).each do|fname|
      if match = PAGE_FILENAME_REGEX.match(fname)
        if match[1]
          h[ match[1][1, match[1].size ] ] = url_prefix + '/' + fname
        else
          h['en-US'] = url_prefix + '/' + fname
        end
      end
    end
    h
  end

  ##
  # If has file_path of saved page, would delete all files of page folder.
  def delete_files
    if file_path.present?
      FileUtils.rm_r(page_dir, force: true)
      self.update_attributes(file_path: nil)
    end
  end


  #############################
  # Data exports

  # @return <Array>
  def to_csv_row_values
    self.class.csv_columns.collect do |c|
      self.send(c.to_sym)
    end
  end


  def self.csv_columns
    %w|relative_page_url page_type|
  end

  # @return <CSV::Row>
  def self.csv_header
    cols = csv_columns
    CSV::Row.new(cols.collect(&:to_sym), cols, true)
  end

  # Sets page_type,
  def normalize
    self.page_type = scraper_class.page_type_for(page_url) if page_type.blank?
    uri = page_url.index('ruby/object') ? YAML::load(page_url) : URI(page_url)
    self.page_url = uri.to_s
    self.page_url = 'http:' + page_url if uri.scheme.nil? && page_url.starts_with?('//')
    self.url_path = uri.path
    self.url_params = uri.sorted_query(false)
    self.title = title.squish if title
  end

end
