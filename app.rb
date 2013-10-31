require 'sinatra/base'
require 'sinatra/asset_pipeline'
require 'rack/csrf'
require 'mail'
require 'haml'
require 'newrelic_rpm'
require 'digest/sha1'
require 'redis'
require 'coffee_script'
require 'sass'
require 'uglifier'

require './lib/oapi.rb'

class ODLanding < Sinatra::Base

  configure do
    enable :sessions

    set :assets_precompile, %w(*.js *.css *.png *.jpg *.svg)

    set :assets_prefix, %w(assets)

    set :assets_css_compressor, :sass

    set :assets_js_compressor, :uglifier

    register Sinatra::AssetPipeline
    use Rack::Csrf, :raise => true
    set :assume_xhr_is_js, false

    set :sendto, ENV['SUBMIT_EMAIL_ADDRESS']
    set :optimizely_token, ENV['OPTIMIZELY_TOKEN']
    set :mixpanel_token, ENV['MIXPANEL_TOKEN']
    set :redirect_policy, (ENV['REDIRECT_POLICY'] || :noredirect).downcase.to_sym
    set :ga_account, ENV['GA_ACCOUNT_ID']

    uri = URI.parse(ENV["REDISTOGO_URL"] || 'redis://localhost')
    REDIS = Redis.new(host: uri.host,
                      port: uri.port,
                      password: uri.password)
  end

  configure :development do
    require 'sinatra/reloader'
    require 'logger'
    require 'pry'
    require 'profiler'

    register Sinatra::Reloader
    set :logger, Logger.new($stdout)

    also_reload "#{root}/lib/*.rb"
  end

  configure :production do
    set :server, :puma

    Mail.defaults do
      delivery_method :smtp, :address   => 'smtp.sendgrid.net',
                             :port      => 587,
                             :user_name => ENV['SENDGRID_USERNAME'],
                             :password  => ENV['SENDGRID_PASSWORD'],
                             :authentication => 'plain',
                             :enable_starttls_auto => true
    end
  end

  before do
    @ct = Rack::Utils.escape_html(params[:ct])
    @ct = "Freelancers" if @ct.nil? or @ct.blank?
    @ct_singular = @ct.gsub(/s$/, '')

    # Tracking
    %w(vt_ref vt_kw vt_adg vt_cmp vt_src vt_med vt_device query).each do |key|
      instance_variable_set("@#{key}", Rack::Utils.escape_html(params[:"#{key}"]))
    end
  end

  before %r{/o/landing(:?S[12]?)?} do
    if settings.redirect_policy == :site
      redirect to("https://www.odesk.com#{request.fullpath}"), 302
    elsif settings.redirect_policy == :schedule and
      (Time.now.saturday? or
      Time.now.sunday? or
      !Time.now.hour.between?(9, 16))

      redirect to("https://www.odesk.com#{request.fullpath}"), 302
    end
  end

  get %r{^/$|^/o/landing(:?S\d?)?} do
    session[:full_query] = request.query_string
    session[:query] = @query
    skill = session[:skill] = Rack::Utils.escape_html(params[:skill])
    subcategory = session[:subcat] = Rack::Utils.escape_html(params[:subcategory]).split(" ").map(&:capitalize).join(" ")
    title = session[:title] = Rack::Utils.escape_html(params[:title])
    country = Rack::Utils.escape_html(params[:country])
    rate = Rack::Utils.escape_html(params[:rate]) || '*'

    session[:url] = request.url
    session[:referrer] = request.referrer
    session[:ip] = request.ip
    session[:visit_timestamp] = Time.now.to_s

    q = session[:q] = OApi.build_q(query: @query,
                                   title: title,
                                   skills: skill,
                                   country: country)

    data = is_cached(q)

    unless data
      data = set_cache(q, OApi.profiles(q, subcategory, rate))
    end

    @profiles = data[:profiles]
    @profile_count = (data[:count] - data[:profiles].length).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse

    @keywords = session[:keywords] = [@query, title, skill,
                                      subcategory].compact.reject(&:empty?)

    haml :context
  end

  post '/send' do
    @title = Rack::Utils.escape_html(params[:title])
    @desc = Rack::Utils.escape_html(params[:desc])
    @scroll_count = Rack::Utils.escape_html(params[:scroll_count]).to_i
    @email = Rack::Utils.escape_html(params[:email])

    return if @title.empty? or @desc.length < 50 or @email.empty?

    body_html = haml(:email, layout: false)
    body_text = "Title: #{@title}\nDescription: #{@desc}\nEmail: #{@email}"

    sendto = settings.sendto
    subject_text = "Landing Page - #{@email} - #{@title}"

    Mail.deliver do
      from      "odysseas@odesk.com"
      to        sendto
      subject   subject_text

      text_part do
        body body_text
      end

      html_part do
        content_type 'text/html; charset=UTF-8'
        body body_html
      end
    end

    if request.xhr?
      return haml :_confirmation, layout: false
    end

    redirect to('/?confirmation')
  end

  get '/autocomplete' do
    q = OApi.build_q(query: params[:q])
    suggestions = OApi.suggestions(q)

    suggestions.to_json
  end

  not_found do
    haml :'404', layout: false
  end

  helpers do
    def csrf_token
      Rack::Csrf.csrf_token(env)
    end

    def csrf_tag
      Rack::Csrf.csrf_tag(env)
    end

    def highlight(text, keywords)
      keywords = Array(keywords)

      return text if keywords.empty?
      text.to_s.gsub(/(#{keywords.join('|')})/iu, "<strong>\\1</strong>")
    end

    def truncate(text, length=30, ellipsis=" ...")
      text.to_s.split(' ').slice(0, length).join(' ') + ellipsis
    end

    def is_cached(q)
      q = q.to_s
      tag = "query:#{q}"
      data = REDIS.get(tag)

      if data
        etag Digest::SHA1.hexdigest(q)
        ttl = REDIS.ttl(tag)
        response.header['X-Redis-TTL'] = ttl.to_s
        response.header['X-Redis-Cache'] = 'HIT'
        return JSON.parse(data, symbolize_names: true)
      end
    end

    def set_cache(q, data)
      q = q.to_s
      etag Digest::SHA1.hexdigest(q)
      tag = "query:#{q}"
      response.header['X-Redis-Cache'] = 'MISS'
      REDIS.setex(tag, 345600, data.to_json)

      data
    end
  end

end
