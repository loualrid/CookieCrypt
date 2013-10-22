module CookieCrypt
  module Schema

    def cookie_crypt_login_attempts_count
      apply_devise_schema :cookie_crypt_login_attempts_count, Integer, :default => 0
    end
  end
end
