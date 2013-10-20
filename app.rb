require 'sinatra/base'
require 'sinatra/reloader'
require 'rack/csrf'
require 'mail'
require 'logger'
require 'sass/plugin/rack'
require 'rack/coffee'
require 'haml'

require './oapi.rb'

class ODLanding < Sinatra::Base

  configure do
    enable :sessions
    Sass::Plugin.options[:style] = :compressed
    Sass::Plugin.options[:css_location] = "#{public_folder}/css"
    Sass::Plugin.options[:template_location] = "#{public_folder}/sass"
    use Sass::Plugin::Rack

    use Rack::Csrf, :raise => true
    use Rack::Coffee, root: public_folder, urls: '/js'
  end

  configure :development do
    register Sinatra::Reloader
    set :logger, Logger.new($stdout)
  end

  configure :production do
    set :server, :puma
  end

  get '/' do
    @ct = Rack::Utils.escape_html(params[:ct])
    @ct_singular = @ct.gsub(/s$/, '')
    query = Rack::Utils.escape_html(params[:query])
    skill = Rack::Utils.escape_html(params[:skill])
    subcategory = Rack::Utils.escape_html(params[:subcategory])
    hi = Rack::Utils.escape_html(params[:hi])
    title = Rack::Utils.escape_html(params[:title])

    @profiles = OApi.profiles(query, title, skill)
    @keyword = if !query.nil?
                 query
               elsif !title.nil?
                 title
               elsif !skill.nil?
                 skill
               end

    haml :context
  end

  post '/send' do
    title = Rack::Utils.escape_html(params[:title])
    desc = Rack::Utils.escape_html(params[:desc])
    email = Rack::Utils.escape_email(params[:email])

    Mail.deliver do
      from      email
      to        'example@localhost'
      subject   'Landing page submission'

      text_part do
        body "Title: #{title}\nDescription: #{desc}"
      end

      html_part do
        content_type 'text/html; charset=UTF-8'
        # probably need to render mailer view here
        body "Title: #{title}\nDescription: #{desc}"
      end
    end
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
      text.gsub(/(#{keyword})/i, "<strong>\\1</strong>")
    end
  end

end
