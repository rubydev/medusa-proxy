$LOAD_PATH.unshift File.expand_path('../../', __FILE__)

require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'turn' unless ENV["TM_FILEPATH"]

require 'proxy'