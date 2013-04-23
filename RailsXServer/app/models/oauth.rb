class Oauth < ActiveRecord::Base
  attr_accessible :provider,:uid,:token,:secret,:name,:icon,:fullname
  belongs_to :user
end
