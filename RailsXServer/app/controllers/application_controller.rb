class ApplicationController < ActionController::Base
  protect_from_forgery
  CONSUMER_KEY=ENV['CONSUMER_KEY']
  CONSUMER_SECRET=ENV['CONSUMER_SECRET']
  CALLBACK_PATH="/index/oauth_callback"
  def consumer
    OAuth::Consumer.new(CONSUMER_KEY,CONSUMER_SECRET,{site:"http://twitter.com"})
  end
  def authorized?
    session[:oauth_token]
  end
  Twitter.configure do |config|
    config.consumer_key=CONSUMER_KEY
    config.consumer_secret=CONSUMER_SECRET
  end
  def twitter
    Twitter::Client.new session[:oauth_token]
  end
end
