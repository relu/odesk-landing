require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/respond_to'
require 'rack/csrf'
require 'mail'
require 'logger'
require 'sass/plugin/rack'
require 'rack/coffee'
require 'haml'

require './lib/oapi.rb'

class ODLanding < Sinatra::Base

  configure do
    enable :sessions
    Sass::Plugin.options[:style] = :compressed
    Sass::Plugin.options[:css_location] = "#{public_folder}/css"
    Sass::Plugin.options[:template_location] = "#{public_folder}/sass"
    use Sass::Plugin::Rack

    use Rack::Csrf, :raise => true
    use Rack::Coffee, root: public_folder, urls: '/js'
    register Sinatra::RespondTo
    set :assume_xhr_is_js, false

    set :optimizely_token, ENV['OPTIMIZELY_TOKEN']
    set :mixpanel_token, ENV['MIXPANEL_TOKEN']
    set :redirect_policy, (ENV['REDIRECT_POLICY'] || :noredirect).downcase.to_sym
  end

  configure :development do
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
  end

  before %r{/o/landing(:?S[12]?)?} do
    if settings.redirect_policy == :site
      redirect to("https://www.odesk.com#{request.fullpath}"), 302
    elsif settings.redirect_policy == :schedule and Time.now.hour.between?(9, 16)
      redirect to("https://www.odesk.com#{request.fullpath}"), 302
    end
  end

  get %r{^/$|^/o/landing(:?S\d?)?} do
    query = session[:query] = Rack::Utils.escape_html(params[:query])
    skill = session[:skill] = Rack::Utils.escape_html(params[:skill])
    subcategory = session[:subcat] = Rack::Utils.escape_html(params[:subcategory])
    title = session[:title] = Rack::Utils.escape_html(params[:title])
    country = Rack::Utils.escape_html(params[:country])
    rate = Rack::Utils.escape_html(params[:rate]) || '*'

    session[:url] = request.url
    session[:referrer] = request.referrer
    session[:ip] = request.ip
    session[:visit_timestamp] = Time.now.to_s

    q = session[:q] = OApi.build_q(query: query,
                                   title: title,
                                   skills: skill,
                                   subcategory: subcategory,
                                   country: country)

    @profiles = OApi.profiles(q, rate)
    @keyword = session[:keyword]= if !query.nil?
                 query
               elsif !title.nil?
                 title
               elsif !skill.nil?
                 skill
               elsif !subcategory.nil?
                 subcategory
               end

    haml :context
  end

  post '/send' do
    @title = Rack::Utils.escape_html(params[:title])
    @desc = Rack::Utils.escape_html(params[:desc])
    @scroll_count = Rack::Utils.escape_html(params[:scroll_count]).to_i
    email = params[:email]

    body_html = haml(:email, layout: false)

    Mail.deliver do
      from      email
      to        'aurelcanciu@odesk.com'
      subject   'Landing page submission'

      text_part do
        body "Title: #{@title}\nDescription: #{@desc}"
      end

      html_part do
        content_type 'text/html; charset=UTF-8'
        body body_html
      end
    end

    respond_to do |format|
      format.html do
        if request.xhr?
          return haml :_confirmation, layout: false
        end

        redirect to('/?confirmation')
      end
      format.json { {success: 1}.to_json }
    end
  end

  get '/autocomplete' do
    q = OApi.build_q(query: params[:q])
    suggestions = OApi.suggestions(q)

    suggestions.to_json
  end

  helpers do
    def csrf_token
      Rack::Csrf.csrf_token(env)
    end

    def csrf_tag
      Rack::Csrf.csrf_tag(env)
    end

    def highlight(text, keyword)
      return text if keyword.nil? or keyword == ''
      text.to_s.gsub(/(#{keyword})/i, "<strong>\\1</strong>")
    end
  end

end
