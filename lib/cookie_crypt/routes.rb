module ActionDispatch::Routing
  class Mapper
    protected

      def devise_cookie_crypt(mapping, controllers)
        resource :cookie_crypt, :only => [:show, :update], :path => mapping.path_names[:cookie_crypt], :controller => controllers[:cookie_crypt]
      end
  end
end
