class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :user_signed_in?,:current_user,:social_info
  CONSUMER_KEY=ENV['CONSUMER_KEY']
  CONSUMER_SECRET=ENV['CONSUMER_SECRET']
  NEWS_TOKEN={oauth_token:ENV['NEWS_ACCESS_TOKEN'],oauth_token_secret:ENV['NEWS_TOKEN_SECRET']}
  def consumer
    OAuth::Consumer.new(CONSUMER_KEY,CONSUMER_SECRET,{site:"http://twitter.com"})
  end
  
  def current_user_icon
    if social_info
      social_info[:icon]
    else
      n=session[:user_id] || request.session_options[:id][0,4].hex
      "/assets/icon/#{n%32}.png"
    end
  end
  def current_user_name
    if user_signed_in?
      current_user.name
    else
      social_info[:name] if social_info
    end
  end
  def current_user
    uid=session[:user_id]
    if uid
      user=User.where(id:uid).first
      session.delete :user_id if user.nil?
      user
    end
  end
  def user_signed_in?
    session[:user_id]!=nil&&current_user!=nil
  end
  def social_info
    session[:oauth][:info] if session[:oauth]
  end
  Twitter.configure do |config|
    config.consumer_key=CONSUMER_KEY
    config.consumer_secret=CONSUMER_SECRET
  end
  def twitter(token=nil)
    Twitter::Client.new token||session[:oauth][:token]
  end
  def news_twitter
    Twitter::Client.new NEWS_TOKEN
  end
end
