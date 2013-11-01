ENV['RACK_ENV'] = 'test'

require './app'
require 'rspec'
require 'capybara'
require 'capybara/rspec'
require 'capybara/webkit'
require 'rack/test'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

Capybara.javascript_driver = :webkit
Capybara.app = ODLanding.new

def app
  ODLanding
end
