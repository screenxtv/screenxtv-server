class Oauth < ActiveRecord::Base

  attr_accessible :provider,:uid,:token,:secret,:name,:icon,:display_name
  belongs_to :user
  def info
    {display_name:display_name, name:name, icon:icon}
  end
  def to_hash
    hash = {}
    keys = [:provider,:uid,:token,:secret,:name,:icon,:display_name]
    keys.each do |key|
      hash[key] = self[key]
    end
    hash
  end
end
