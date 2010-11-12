# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'medusa-proxy/version'

Gem::Specification.new do |s|
  s.name        = "medusa-proxy"
  s.version     = Medusa::Proxy::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Karel Minarik']
  s.email       = ['karmi@karmi.cz']
  s.homepage    = "http://git.internal.ataxo.com/?p=medusa-proxy.git"
  s.summary     = "A Reverse/Forward Proxy"
  s.description = "A Reverse/Forward Proxy Based on EventMachine and 'em-proxy' Rubygem"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "bundler", "~> 1.0.0"
  s.add_dependency "em-proxy"
  s.add_dependency "rest-client"
  s.add_dependency "yajl-ruby"
  s.add_dependency "redis"
  s.add_dependency "ansi"

  s.add_development_dependency "shoulda"
  s.add_development_dependency "turn"
  s.add_development_dependency "fakeweb"

  s.files        = `git ls-files`.split("\n")
  s.require_path = 'lib'

  s.bindir             = 'bin'
  s.executables        = ['medusa']
  s.default_executable = 'medusa'
end
