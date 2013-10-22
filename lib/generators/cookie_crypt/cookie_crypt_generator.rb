module CookieCryptable
  module Generators
    class CookieCryptGenerator < Rails::Generators::NamedBase
      namespace "cookie_crypt"
      desc "Adds :cookie_cryptable directive in the given model.
       It also generates an active record migration."

      def inject_cookie_crypt_content
        paths = [File.join("app", "models", "#{file_path}.rb"),File.join("config", "initializers", "devise.rb")]
        inject_into_file(paths[0], "cookie_cryptable, :", :after => "devise :") if File.exists?(paths[0])
        if File.exists?(paths[1])
          inject_into_file(paths[1], "\n  # ==> Cookie Crypt Configuration Parameters\n  config.max_cookie_crypt_login_attempts = 3
            \n  # For cookie_deletion_time_frame field, make sure your timeframe parses into an actual date and is a string
            \n  config.cookie_deletion_time_frame = '30.days.from_now'", after: "Devise.setup do |config|")
        end
      end

      source_root File.expand_path('../../../../app/views/devise/cookie_crypt', __FILE__)

      def generate_files
        Dir.mkdir("app/views/devise") unless Dir.exists?("app/views/devise")
        unless Dir.exists?("app/views/devise/cookie_crypt")
          Dir.mkdir("app/views/devise/cookie_crypt") 
          copy_file "max_login_attempts_reached.html.erb", "app/views/devise/cookie_crypt/max_login_attempts_reached.html.erb"
          copy_file "show.html.erb", "app/views/devise/cookie_crypt/show.html.erb"
        end
      end
      
      hook_for :orm
    end
  end
end
