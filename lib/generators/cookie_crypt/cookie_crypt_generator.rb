module CookieCryptable
  module Generators
    class CookieCryptGenerator < Rails::Generators::NamedBase
      namespace "cookie_crypt"
      desc "Automates setup process, will also update between versions."

      #BEGIN 1.0 generator
      def inject_1_0_cookie_crypt_content
        if ActiveRecord::Base.class_eval("#{table_name.camelize.singularize}.inspect['security_question_one: string'].blank?")
          puts "Beginning 1.0 content injection..."
          paths = [File.join("app", "models", "#{file_path}.rb"),File.join("config", "initializers", "devise.rb")]
          inject_into_file(paths[0], "cookie_cryptable, :", :after => "devise :") if File.exists?(paths[0])
          if File.exists?(paths[1])
            inject_into_file(paths[1], "\n  # ==> Cookie Crypt Configuration Parameters\n  config.max_cookie_crypt_login_attempts = 3
              \n  # For cookie_deletion_time_frame field, make sure your timeframe parses into an actual date and is a string
              \n  config.cookie_deletion_time_frame = '30.days.from_now'", after: "Devise.setup do |config|")
          end
        end
      end

      source_root File.expand_path('../../../../app/views/devise/cookie_crypt', __FILE__)

      def generate_1_0_files
        Dir.mkdir("app/views/devise") unless Dir.exists?("app/views/devise")
        unless Dir.exists?("app/views/devise/cookie_crypt")
          puts "Beginning 1.0 views creation..."
          Dir.mkdir("app/views/devise/cookie_crypt") 
          copy_file "max_login_attempts_reached.html.erb", "app/views/devise/cookie_crypt/max_login_attempts_reached.html.erb"
          copy_file "show.html.erb", "app/views/devise/cookie_crypt/show.html.erb"
        end
      end
      
      source_root File.expand_path(__FILE__)

      #BEGIN 1.1 generator
      def inject_1_1_cookie_crypt_content
        if ActiveRecord::Base.class_eval("#{table_name.camelize.singularize}.inspect['security_hash: text'].blank?")
          puts "Beginning 1.1 content injection..."
          paths = [File.join("app", "models", "#{file_path}.rb"),File.join("config", "initializers", "devise.rb")]
          if File.exists?(paths[1])
            inject_into_file(paths[1], "\n  # cookie_crypt_auth_through manages the various styles of authenticating through two factor when the need arises.
              \n  # Valid options are: :one_question_cyclical, :one_question_random, :two_questions_cyclical, :two_questions_random, :all_questions
              \n  config.cookie_crypt_auth_through = :one_question_cyclical
              \n  # cookie_crypt_minimum_questions determines how many questions and answers the user must create the first time they are auth'ing through CC
              \n  # This option must be greater than or equal to 2.
              \n  config.cookie_crypt_minimum_questions = 3
              \n  # cycle_question_on_fail_count determines how many tries the user gets per question(s) before the system changes the questions shown
              \n  # It is recommended to set this to at least 2, but 1 is allowed. This value is ignored if the system is set to :all_questions
              \n  config.cycle_question_on_fail_count = 2
              \n  # enable_custom_question_counts allows users to have *more* than the minimum number of questions. This works via ajax and javascript.
              \n  config.enable_custom_question_counts = false", after: "  # ==> Cookie Crypt Configuration Parameters")
          end
        end
      end

      source_root File.expand_path('../../../../app/views/devise/cookie_crypt', __FILE__)

      def generate_1_1_files
        unless File.exist?("app/views/devise/cookie_crypt/show.js.erb")
          puts "Beginning 1.1 views creation..."
          copy_file "show.js.erb", "app/views/devise/cookie_crypt/show.js.erb"
          copy_file "_extra_fields.html.erb", "app/views/devise/cookie_crypt/_extra_fields.html.erb"
          File.delete("app/views/devise/cookie_crypt/show.html.erb")
          copy_file "show.html.erb", "app/views/devise/cookie_crypt/show.html.erb"

          puts "Please run rake db:migrate then run this generator again to cleanup unused fields."
        end
      end

      def generate_1_1_update
        unless ActiveRecord::Base.class_eval("#{table_name.camelize.singularize}.inspect['security_hash: text'].blank?")
          unless ActiveRecord::Base.class_eval("#{table_name.camelize.singularize}.inspect['security_question_one: string'].blank?")
            puts "Beginning data cleanup, moving 1.0 database data to 1.1 database style..."
            objs = ActiveRecord::Base.class_eval("#{table_name.camelize.singularize}.all")
            objs.each do |obj|
              next if obj.security_question_one.blank?
              h = {}
              h["security_question_1"] = obj.security_question_one
              h["security_answer_1"]   = obj.security_answer_one
              h["security_question_2"] = obj.security_question_two
              h["security_answer_2"] = obj.security_answer_two
              obj.security_hash = h.to_s

              obj.save

              puts "#{obj.security_hash}"
            end

            puts "Completed data cleanup, database is now 1.1 ready."
            puts "Generating cleanup migration that will remove now unneeded security_question_one, security_answer_one, security_question_two, security_answer_two fields."

            $generate_1_1_cleanup_migration = true
          end
        end
      end

      hook_for :orm
    end
  end
end
