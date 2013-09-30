require 'carrierwave'

CarrierWave::SanitizedFile.sanitize_regexp = /[^[:word:]\.\-\+]/
CarrierWave.configure do |config|
  config.root = File.expand_path __dir__+"/../public"
end

class MyUploader < CarrierWave::Uploader::Base
  storage :file
  def filename
    @name ||= "#{Time.now.strftime('%Y%m%d%H%M%S')}-#{super}"
  end
  def store_dir
    'uploads'
  end
end
