class ApplicationController < ActionController::Base
  include ControllerHelpers::SiteWall
  include ControllerHelpers::PageFlow

  include Spree::Core::ControllerHelpers::Auth
  include Spree::Core::ControllerHelpers::Order
  include ::ControllerHelpers::Order # override some of methods in Spree's original

  require File.join(Rails.root, 'lib/spree/core/controller_helpers/cart') # somehow the config/application.rb cannot load lib/*
  include Spree::Core::ControllerHelpers::Cart

  before_action :load_cart

  ##
  # These from
  def action
    params[:action].to_sym
  end

  def authorize_admin
    if respond_to?(:model_class, true) && model_class
      record = model_class
    else
      record = controller_name.to_sym
    end
    authorize! :admin, record
    authorize! action, record
  end

  def default_url_options
    if Rails.env.staging?
      SITE_DOMAIN.present? ? {:host => SITE_DOMAIN } : { only_path: true }
    else
      {}
    end
  end

  def load_cart
    if %w|GET PATCH|.include?(request.method)
      load_orders
    end
  end

  protected


end
