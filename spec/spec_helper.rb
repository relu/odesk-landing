ENV['RACK_ENV'] = 'test'

require './app'
require 'rspec'
require 'capybara'
require 'capybara/rspec'
require 'capybara/webkit'
require 'headless'
require 'rack/test'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

Capybara.javascript_driver = :webkit
Capybara.app = ODLanding.new

Headless.new(:display => Process.pid, :reuse => false)

def app
  ODLanding
end
