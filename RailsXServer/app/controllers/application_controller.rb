class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :user_signed_in?,:current_user
  CONSUMER_KEY=ENV['CONSUMER_KEY']
  CONSUMER_SECRET=ENV['CONSUMER_SECRET']
  NEWS_TOKEN={oauth_token:ENV['NEWS_ACCESS_TOKEN'],oauth_token_secret:ENV['NEWS_TOKEN_SECRET']}
  CALLBACK_PATH="/index/oauth_callback"
  def consumer
    OAuth::Consumer.new(CONSUMER_KEY,CONSUMER_SECRET,{site:"http://twitter.com"})
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
    !current_user.nil?
  end
  Twitter.configure do |config|
    config.consumer_key=CONSUMER_KEY
    config.consumer_secret=CONSUMER_SECRET
  end
  def twitter
    Twitter::Client.new session[:oauth_token]
  end
  def news_twitter
    Twitter::Client.new NEWS_TOKEN
  end
end
