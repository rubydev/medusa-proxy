$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

ENV['MEDUSA_ENV'] = 'test'

require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'turn' unless ENV["TM_FILEPATH"]

require 'medusa-proxy'
