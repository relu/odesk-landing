require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc 'Preload API data into cache'
task :preload_data do
  require 'pp'
  require 'csv'
  require 'cgi'
  require 'redis'
  require './lib/oapi.rb'

  uri = URI.parse(ENV["REDISTOGO_URL"] || 'redis://localhost')
  REDIS = Redis.new(host: uri.host,
                    port: uri.port,
                    password: uri.password)

  CSV.foreach 'ads.csv' do |row|
    url = row.first.gsub(/.*\?/, '')
    parsed = CGI::parse(url)

    rate = parsed['rate'].first

    params = {
      title: parsed['title'].first,
      skills: parsed['skill'].first,
      subcategory: parsed['subcategory'].first,
      country: parsed['country'].first
    }

    q = "#{parsed['query'].first} "

    params.each do |key, value|
      q += "#{key.to_s}:#{value} " unless value.nil? or value.empty?
    end

    q.strip!

    tag = "query:#{q}"

    next if REDIS.get(tag)

    puts "Caching: #{q}\n"
    data = OApi.profiles(q, rate)
    REDIS.setex(tag, 3600, data.to_json)
  end
end

require 'sinatra/asset_pipeline/task.rb'
require './app.rb'

Sinatra::AssetPipeline::Task.define! ODLanding
