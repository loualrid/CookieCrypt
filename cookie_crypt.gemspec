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
    * Configurable max login attempts
    * per user level control if he really need two factor authentication
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
end
