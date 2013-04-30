class Oauth < ActiveRecord::Base
  attr_accessible :provider,:uid,:token,:secret,:name,:icon,:display_name
  belongs_to :user
end
