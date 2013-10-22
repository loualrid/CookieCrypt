module CookieCrypt
  class Engine < ::Rails::Engine
    ActiveSupport.on_load(:action_controller) do
      include CookieCrypt::Controllers::Helpers
    end
  end
end
