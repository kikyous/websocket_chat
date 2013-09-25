require 'pathname'
require 'nokogiri'
require 'open-uri'

doc = Nokogiri::HTML(open('http://www.emoji-cheat-sheet.com/'))
doc.css('#emoji-people .emoji').each do |e|
  name = Pathname.new(e['data-src']).basename
  puts "':#{name.to_s.split('.').first}:' :  '#{name}',"
end
