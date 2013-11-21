require 'cookie_crypt/hooks/cookie_cryptable'
module Devise
  module Models
    module CookieCryptable
      extend ActiveSupport::Concern

      module ClassMethods
        ::Devise::Models.config(self, :max_cookie_crypt_login_attempts, :cookie_deletion_time_frame, :cookie_crypt_auth_through, :cookie_crypt_minimum_questions, :cycle_question_on_fail_count, :enable_custom_question_counts)
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
