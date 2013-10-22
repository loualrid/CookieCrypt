module CookieCrypt
  module Controllers
    module Helpers
      extend ActiveSupport::Concern

      included do
        before_filter :handle_cookie_crypt
      end

      private

      def handle_cookie_crypt
        unless devise_controller?
          Devise.mappings.keys.flatten.any? do |scope|
            if signed_in?(scope) and warden.session(scope)[:need_cookie_crypt_auth]
              handle_failed_cookie_crypt_auth(scope)
            end
          end
        end
      end

      def handle_failed_cookie_crypt_auth(scope)
        if request.format.present? and request.format.html?
          session["#{scope}_return_tor"] = request.path if request.get?
          redirect_to cookie_crypt_auth_path_for(scope)
        else
          render nothing: true, status: :unauthorized
        end
      end

      def cookie_crypt_auth_path_for(resource_or_scope = nil)
        scope = Devise::Mapping.find_scope!(resource_or_scope)
        change_path = "#{scope}_cookie_crypt_path"
        send(change_path)
      end

    end
  end
end
