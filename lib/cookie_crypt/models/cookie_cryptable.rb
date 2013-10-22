require 'cookie_crypt/hooks/cookie_cryptable'
module Devise
  module Models
    module CookieCryptable
      extend ActiveSupport::Concern

      module ClassMethods
        ::Devise::Models.config(self, :max_cookie_crypt_login_attempts, :cookie_deletion_time_frame)
      end

      def need_cookie_crypt_auth?(request)
        true
      end

      def max_cookie_crypt_login_attempts?
        cookie_crypt_attempts_count >= self.class.max_cookie_crypt_login_attempts
      end
    end
  end
end
