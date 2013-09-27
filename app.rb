require 'rubygems'
require 'em-websocket'
require 'slim'
require 'sinatra/base'
require "sinatra/cookies"
require 'thin'
require 'cgi/cookie'
require 'nokogiri'

COOKIE_KEY = 'rack.session'
COOKIE_SECRET = '*&(^B234312341234'

def _sanitize text
  x = Nokogiri::HTML.fragment text
  x.css('script,iframe').remove
  x.css('a').each{|a| a['target']='_blank'}
  x.css('audio,video').each{|m| m.remove_attribute('autoplay')}
  x.to_s
end

class Channel < EM::Channel
  @@channels = {}
  attr_accessor :name, :histroy, :current_sub

  def path
    self.name=='/' ? '/' : "/channel/#{self.name}"
  end

  def initialize name
    self.name    = name
    self.histroy = []
    super()
  end

  def other_subs
    @subs.reject{|sid| sid== self.current_sub}
  end

  def send(*item)
    item = item.dup
    EM.schedule { item.each { |i| other_subs.values.each { |s| s.call i } } }
  end

  def secure_push title, content
    msg = "<dl><dt><span class='badge'>#{title} #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}</span></dt><dd>#{content}</dd></dl>"
    msg = _sanitize msg
    self.send msg
    self.histroy << msg
  end

  def to_s
    "#{name}(#{@subs.length}人在线)"
  end

  class << self
    def find_or_init channel
      @@channels[channel] ||= new(channel)
    end

    def public
      @@channels.reject{|key,value| key.start_with? '_'}
    end

    alias_method :[], :find_or_init
  end
end

EventMachine.run do
  class App < Sinatra::Base
    enable :logging
    use Rack::Session::Cookie,  :key => COOKIE_KEY,
      :path => '/',
      :expire_after => 2592000, #30 days
      :secret => COOKIE_SECRET

    get '/' do
      channel = '/'
      session[:channel] = channel
      session[:name] ||= "guest#{rand(10000..99999)}"

      @channel=Channel.find_or_init(channel)
      slim :index
    end

    get '/channel/:name' do |name|
      channel = name
      session[:channel] = channel

      @channel = Channel.find_or_init channel
      slim :index
    end

    get '/channel' do
      slim :channels
    end

    post '/username' do
      session[:name] = params[:value]
      halt 200
    end

  end

  EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 1438) do |ws|
    ws.onopen { |handshake|
      define_method :cookie do |key|
        CGI::Cookie::parse(handshake.headers['Cookie'])[key].first
      end
      rack_cookie = Rack::Session::Cookie.new(App)
      bakesale     = cookie 'rack.session'
      session      = rack_cookie.coder.decode(Rack::Utils.unescape(bakesale))
      username     = session['name']
      channel_name = session['channel']
      channel      = Channel.find_or_init channel_name
      sid          = channel.subscribe { |msg| ws.send msg }

      ws.onmessage { |msg|
        channel.current_sub = sid
        channel.secure_push username, msg
      }

      ws.onclose {
        channel.unsubscribe(sid)
      }
    }

  end

  App.run!({:port => 3360})
end
