class Oauth < ActiveRecord::Base
  attr_accessible :provider,:uid,:token,:secret,:name,:icon,:display_name
  belongs_to :user

  def url
    Oauth.url_for provider, name
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
