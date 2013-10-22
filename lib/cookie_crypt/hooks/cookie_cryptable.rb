Warden::Manager.after_authentication do |user, auth, options|
  if user.respond_to?(:need_cookie_crypt_auth?)
    if auth.session(options[:scope])[:need_cookie_crypt_auth] = user.need_cookie_crypt_auth?(auth.request)
    end
  end
end