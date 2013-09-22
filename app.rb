require 'rubygems'
require 'em-websocket'
require 'slim'
require 'sinatra/base'
require "sinatra/cookies"
require 'thin'
require 'cgi/cookie'

require 'action_view'

include ActionView::Helpers::SanitizeHelper

$channel = EM::Channel.new

$histroy = []
EventMachine.run do
  class App < Sinatra::Base
    helpers Sinatra::Cookies
    set :bind, '0.0.0.0'
    enable :logging

    get '/' do
      unless cookies[:name]
        cookies[:name] = "guest#{rand(10000..99999)}"
      end
      slim :index
    end

    post '/' do
      $channel.push "POST>: #{params[:text]}"
    end

    post '/username' do
      cookies[:name] = params[:value]
      halt 200
    end

    get 'admin' do
      slim :admin
    end
  end

  EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8080) do |ws|
    ws.onopen { |handshake|
      sid = $channel.subscribe { |msg| ws.send msg }
      username = CGI::Cookie::parse(handshake.headers['Cookie'])['name'].first

      ws.onmessage { |msg|
        send = "<span class='label'>#{username}</span>: #{msg}"
        send = sanitize send, tags: %w(table th tr td img li strong b span div a audio video p)
        $channel.push send
        $histroy << send
      }

      ws.onclose {
        $channel.unsubscribe(sid)
      }
    }

  end

  App.run!({:port => 5000})
end
