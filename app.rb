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

$channel = {}
$histroy = {}

EventMachine.run do
  class App < Sinatra::Base
    helpers Sinatra::Cookies
    set :bind, '0.0.0.0'
    enable :logging

    get '/' do
      @channel = '/'
      $channel['/'] ||= EM::Channel.new
      cookies[:channel] = "/"
      cookies[:name] ||= "guest#{rand(10000..99999)}"
      slim :index
    end

    get '/channel/:name' do |name|
      @channel = name
      $channel[name] ||= EM::Channel.new
      cookies[:channel] = @channel
      slim :index
    end

    get '/channel' do
      slim :channels
    end

    post '/username' do
      cookies[:name] = params[:value]
      halt 200
    end

    get 'admin' do
      slim :admin
    end
  end

  EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 1438) do |ws|
    ws.onopen { |handshake|
      define_method :cookie do |key|
        CGI::Cookie::parse(handshake.headers['Cookie'])[key].first
      end
      username = cookie('name')
      channel_name  = cookie('channel')
      channel  = $channel[channel_name]
      sid      = channel.subscribe { |msg| ws.send msg }

      ws.onmessage { |msg|
        send = "<tr><td><span class='label'>#{username}</span>: #{msg}</td></tr>"
        send = _sanitize send
        channel.push send
        ($histroy[channel_name] ||= []) << send
      }

      ws.onclose {
        channel.unsubscribe(sid)
      }
    }

  end

  App.run!({:port => 3360})
end
