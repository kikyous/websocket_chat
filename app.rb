require 'slim'
require 'sinatra/base'
require "sinatra/json"
require 'thin'
require 'cgi/cookie'
require 'nokogiri'
require 'em-websocket'
require './lib/uploader'
require "sinatra/activerecord"
require 'carrierwave'
require 'carrierwave/orm/activerecord'
require './model/message'

require 'pry'

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

class App < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  set :database, "sqlite3:///app.sqlite3"
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

  post '/upload' do
    @uploader = MyUploader.new
    @uploader.store!(params['file'])
    json url: @uploader.url, name: @uploader.filename, type: @uploader.filename.split('.').last
  end

  post '/username' do
    session[:name] = params[:value]
    halt 200
  end

end
