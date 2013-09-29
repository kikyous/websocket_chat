require 'carrierwave'

class MyUploader < CarrierWave::Uploader::Base
  storage :file
end
