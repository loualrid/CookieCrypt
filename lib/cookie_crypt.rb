require 'cookie_crypt/version'
require 'devise'
require 'digest'
require 'active_support/concern'

module Devise
  mattr_accessor :max_cookie_crypt_login_attempts, :cookie_deletion_time_frame, :cookie_crypt_auth_through, :cookie_crypt_minimum_questions, :cycle_question_on_fail_count, :enable_custom_question_counts
  @@max_cookie_crypt_login_attempts = 3
  @@cookie_deletion_time_frame = '30.days.from_now'
  @@cookie_crypt_auth_through = :one_question_cyclical
  @@cookie_crypt_minimum_questions = 3
  @@cycle_question_on_fail_count = 2
  @@enable_custom_question_counts = false
end

module CookieCrypt
  autoload :Schema, 'cookie_crypt/schema'
  module Controllers
    autoload :Helpers, 'cookie_crypt/controllers/helpers'
  end
end

Devise.add_module :cookie_cryptable, :model => 'cookie_crypt/models/cookie_cryptable', :controller => :cookie_crypt, :route => :cookie_crypt

require 'cookie_crypt/orm/active_record'
require 'cookie_crypt/routes'
require 'cookie_crypt/models/cookie_cryptable'
require 'cookie_crypt/rails'
