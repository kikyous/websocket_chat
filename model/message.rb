class Message < ActiveRecord::Base
  mount_uploader :file, MyUploader
end
