##
# Sets for the controller a wall requiring extra initial authentication to prevent outside users
# from using our admins or protected pages.
# Requires the environment or system setting variables with names SITE_WALL_NAME and SITE_WALL_PASSWORD.
module ControllerHelpers
  module SiteWall
    extend ActiveSupport::Concern

    %w|SITE_WALL_NAME SITE_WALL_PASSWORD SITE_DOMAIN|.each do |var_name|
      self.const_set var_name, ENV[var_name] || SystemSetting.settings[var_name]
    end

    included do
      before_action :site_wall_authentication
    end

    def site_wall_authentication
      return unless Rails.env.staging? || Rails.env.development?

      if requires_site_wall? && !signed_in_the_site_wall? && request.path != user_access_path && request.path != user_access_login_path
        set_this_as_redirect_back
        logger.info " #{request.path} -> SITE_WALL: #{user_access_path}"
        redirect_to user_access_path
      end
    end

    def requires_site_wall?
      (Mime::Type.lookup(request.format).html? || request.format == 'text/html') &&
          SITE_WALL_NAME.present? && SITE_WALL_PASSWORD.present?
    end

    def signed_in_the_site_wall?
      logger.info "| session[:site_wall_user] #{session[:site_wall_user]}"
      session[:site_wall_user].present? && (session[:site_wall_expire_time].nil? || session[:site_wall_expire_time] > Time.now)
    end
  end
end