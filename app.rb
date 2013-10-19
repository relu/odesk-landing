require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/cache'
require 'rack/csrf'
require 'mail'
require 'logger'
require 'sass/plugin/rack'
require 'rack/coffee'

class ODLanding < Sinatra::Base

  configure do
    enable :sessions
    Sass::Plugin.options[:style] = :compressed
    Sass::Plugin.options[:css_location] = "#{settings.public_folder}/public/css"
    Sass::Plugin.options[:template_location] = "#{settings.public_folder}/public/sass"
    use Sass::Plugin::Rack

    use Rack::Csrf, :raise => true
    use Rack::Coffee, root: settings.public_folder, urls: '/js'
  end

  configure :development do
    register Sinatra::Reloader
    set :logger, Logger.new($stdout)
  end

  configure :production do
    set :server, :puma
    register Sinatra::Cache
    enable :cache_enabled
    set :cache_output_dir, Proc.new { File.join(root, 'public', 'cache') }
  end

  get '/:context' do
    #@context = Context.find_by_name(params[:context])
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
  end

end
