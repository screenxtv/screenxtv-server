class ApplicationController < ActionController::Base
  protect_from_forgery
  CONSUMER_KEY=ENV['CONSUMER_KEY']
  CONSUMER_SECRET=ENV['CONSUMER_SECRET']
  NEWS_TOKEN={oauth_token:ENV['NEWS_ACCESS_TOKEN'],oauth_token_secret:ENV['NEWS_TOKEN_SECRET']}
  CALLBACK_PATH="/index/oauth_callback"
  def consumer
    OAuth::Consumer.new(CONSUMER_KEY,CONSUMER_SECRET,{site:"http://twitter.com"})
  end
  def authorized?
    #session[:oauth_token]
    !session[:user_id].nil?
  end
  def current_user
    uid=session[:user_id]
    User.where(user_id:uid).first if uid
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
