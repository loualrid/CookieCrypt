# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cookie_crypt/version"

Gem::Specification.new do |s|
  s.name        = "cookie_crypt"
  s.version     = CookieCrypt::VERSION.dup
  s.authors     = ["Dmitrii Golub","Louis Alridge"]
  s.email       = ["loualrid@gmail.com"]
  s.homepage    = "https://github.com/loualrid/CookieCrypt"
  s.summary     = %q{Encrypted cookie two factor authentication plugin for devise}
  s.description = <<-EOF
    ### Features ###
    * User customizable security questions and answers
    * Configurable max login attempts & cookie expiration time
    * Per user level of control (Allow certain ips to bypass two-factor)
  EOF

  s.rubyforge_project = "cookie_crypt"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'rails', '>= 3.1.1'
  s.add_runtime_dependency 'devise'
  s.add_runtime_dependency 'useragent'

  s.add_development_dependency 'bundler'
  s.license = 'MIT'
#  s.post_install_message = <<END_DESC
#
#  ********************************************
#
#  1.2 Introduces no new major changes. Running the generator again will not be necessary.
#
#  A major revision was made with the 1.1 update for CookieCrypt.
#
#  You will need to run 'bundle exec rails g cookie_crypt MODEL' again
#
#  to start the upgrade process from 1.0 to 1.1.
#
#  For more information check the homepage at 'https://github.com/loualrid/CookieCrypt'
#
#  ********************************************
#
#END_DESC
end
