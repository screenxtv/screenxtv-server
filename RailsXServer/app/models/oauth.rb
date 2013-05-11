class Oauth < ActiveRecord::Base
  ACCESSIBLE_ATTRIBUTES = [:provider, :uid, :name, :icon, :display_name, :token, :secret]
  attr_accessible *ACCESSIBLE_ATTRIBUTES
  belongs_to :user

  def session_hash
    {}.tap do
      |hash| ACCESSIBLE_ATTRIBUTES.each{|key|hash[key]=self[key]}
    end
  end

  def self.url_for oauth
    case oauth[:provider]
    when 'twitter'
      "http://twitter.com/#{oauth[:name]}"
    when 'facebook'
      "http://www.facebook.com/#{oauth[:name]}"
    end
  end
end
