class Oauth < ActiveRecord::Base
  ACCESSIBLE_ATTRIBUTES = [:provider, :uid, :name, :icon, :display_name, :token, :secret]
  attr_accessible *ACCESSIBLE_ATTRIBUTES
  belongs_to :user

  def url
    Oauth.url_for provider, name
  end

  def session_hash
    hash = {}
    ACCESSIBLE_ATTRIBUTES.each{|key|hash[key]=self[key]}
    hash
  end

  def self.url_for provider, name
    case provider
    when 'twitter'
      "http://twitter.com/#{name}"
    when 'facebook'
      "http://www.facebook.com/#{name}"
    end
  end
end
