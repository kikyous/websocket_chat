require 'rubygems'
require 'em-websocket'
require 'yajl'
require 'slim'
require 'sinatra/base'
require "sinatra/cookies"
require 'thin'

$channel = EM::Channel.new

$histroy = []
EventMachine.run do
  class App < Sinatra::Base
    helpers Sinatra::Cookies
    set :bind, '0.0.0.0'

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
  end

  EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8080) do |ws|
    ws.onopen { |handshake|
      sid = $channel.subscribe { |msg| ws.send msg }
      username = handshake.headers['Cookie'].match(/name=(.+)/)[1]


      ws.onmessage { |msg|
        send = "#{username}: #{msg}"
        $channel.push send
        $histroy << send
      }

      ws.onclose {
        p "CLOSE"
        $channel.unsubscribe(sid)
      }
    }

  end

  App.run!({:port => 5000})
end
