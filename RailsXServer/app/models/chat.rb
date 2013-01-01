class Chat < ActiveRecord::Base
  attr_accessible :name,:icon,:message
  belongs_to :screen
end
