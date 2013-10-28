require 'sinatra/base'
require 'sinatra/respond_to'
require 'rack/csrf'
require 'mail'
require 'sass/plugin/rack'
require 'rack/coffee'
require 'haml'
require 'newrelic_rpm'

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

    set :sendto, ENV['SUBMIT_EMAIL_ADDRESS']
    set :optimizely_token, ENV['OPTIMIZELY_TOKEN']
    set :mixpanel_token, ENV['MIXPANEL_TOKEN']
    set :redirect_policy, (ENV['REDIRECT_POLICY'] || :noredirect).downcase.to_sym
    set :ga_account, ENV['GA_ACCOUNT_ID']
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
    cache_control :public, :max_age => 36000 if self.class.production?

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
                                   subcategory: subcategory,
                                   country: country)

    data = OApi.profiles(q, rate)
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
      text.split(' ').slice(0, length).join(' ') + ellipsis
    end
  end

end
