require './app'
CarrierWave::SanitizedFile.sanitize_regexp = /[^[:word:]\.\-\+]/

EventMachine.run do
  EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 1438) do |ws|
    ws.onopen { |handshake|
      define_method :cookie do |key|
        CGI::Cookie::parse(handshake.headers['Cookie'])[key].first
      end
      begin
        rack_cookie = Rack::Session::Cookie.new(App, :key => COOKIE_KEY,
                                                :secret => COOKIE_SECRET)
        bakesale    = cookie 'rack.session'
        session     = rack_cookie.coder.decode(Rack::Utils.unescape(bakesale))
      rescue
        session = {'name'=>'guest', 'channel'=>'/'}
      end
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
