require 'rails/generators/active_record'

module ActiveRecord
  module Generators
    class CookieCryptGenerator < ActiveRecord::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def copy_cookie_crypt_migration
        migration_template "migration.rb", "db/migrate/cookie_crypt_add_to_#{table_name}"
      end

    end
  end
end
