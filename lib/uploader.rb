require 'carrierwave'

CarrierWave.configure do |config|
  config.root = File.expand_path __dir__+"/../public"
end

class MyUploader < CarrierWave::Uploader::Base
  storage :file
  def store_dir
    'uploads'
  end
end
