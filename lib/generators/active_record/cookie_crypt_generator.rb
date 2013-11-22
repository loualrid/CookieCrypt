require 'rails/generators/active_record'

module ActiveRecord
  module Generators
    class CookieCryptGenerator < ActiveRecord::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      #This should only be triggered on a system that has no previous install(s)
      def copy_cookie_crypt_migration_all
        if ActiveRecord::Base.class_eval("#{table_name.camelize.singularize}.inspect['security_question_one: string'].blank?") &&
          ActiveRecord::Base.class_eval("#{table_name.camelize.singularize}.inspect['security_hash: text'].blank?")

          @ignore_other_migrations = true
          migration_template "migration_complete.rb", "db/migrate/cookie_crypt_complete_install_add_to_#{table_name}"
        end
      end

      def copy_cookie_crypt_migration_1_0
        if ActiveRecord::Base.class_eval("#{table_name.camelize.singularize}.inspect['security_question_one: string'].blank?") &&
          !@ignore_other_migrations

          migration_template "migration.rb", "db/migrate/cookie_crypt_add_to_#{table_name}"
        end
      end

      def copy_cookie_crypt_migration_1_1
        if ActiveRecord::Base.class_eval("#{table_name.camelize.singularize}.inspect['security_hash: text'].blank?") &&
          !@ignore_other_migrations

          migration_template "migration_1_1.rb", "db/migrate/cookie_crypt_1_1_update_to_#{table_name}"
        end
      end

      def copy_cookie_crypt_migration_1_1_cleanup
        if $generate_1_1_cleanup_migration
          migration_template "migration_1_1_cleanup.rb", "db/migrate/cookie_crypt_1_1_cleanup_to_#{table_name}"
        end
      end
    end
  end
end
