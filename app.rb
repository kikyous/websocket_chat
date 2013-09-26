require 'rubygems'
require 'em-websocket'
require 'slim'
require 'sinatra/base'
require "sinatra/cookies"
require 'thin'
require 'cgi/cookie'
require 'nokogiri'

def _sanitize text
  x = Nokogiri::HTML.fragment text
  x.css('script').remove
  x.css('a').each{|a| a['target']='_blank'}
  x.css('audio,video').each{|m| m.remove_attribute('autoplay')}
  x.to_s
end

class Channel < EM::Channel
  @@channels = {}
  attr_accessor :name, :histroy

  def path
    self.name=='/' ? '/' : "/channel/#{self.name}"
  end

  def initialize name
    self.name    = name
    self.histroy = []
    super()
  end

  def secure_push title, content
    msg = "<dl><dt><span class='badge badge-success'>#{title} #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}</span></dt><dd>#{content}</dd></dl>"
    msg = _sanitize msg
    self.push msg
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
  find_or_init '/'
end

EventMachine.run do
  class App < Sinatra::Base
    helpers Sinatra::Cookies
    set :cookie_options, :expires => Time.now + 3600*24*30
    enable :logging

    get '/' do
      channel = '/'
      cookies[:channel] = channel
      cookies[:name] ||= "guest#{rand(10000..99999)}"

      @channel=Channel.find_or_init(channel)
      slim :index
    end

    get '/channel/:name' do |name|
      channel = name
      cookies[:channel] = channel

      @channel = Channel.find_or_init channel
      slim :index
    end

    get '/channel' do
      slim :channels
    end

    post '/username' do
      cookies[:name] = params[:value]
      halt 200
    end

    get '/admin/:name' do |name|
      Channel[name].secure_push 'jjjjjjjj'
      'jjjjjjjj'
    end
  end

  EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 1438) do |ws|
    ws.onopen { |handshake|
      define_method :cookie do |key|
        CGI::Cookie::parse(handshake.headers['Cookie'])[key].first
      end
      username     = cookie('name')
      channel_name = cookie('channel')
      channel      = Channel.find_or_init channel_name
      sid          = channel.subscribe { |msg| ws.send msg }

      ws.onmessage { |msg|
        channel.secure_push username, msg
      }

      ws.onclose {
        channel.unsubscribe(sid)
      }
    }

  end

  App.run!({:port => 3360})
end
