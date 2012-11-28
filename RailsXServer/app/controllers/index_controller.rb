class IndexController < ApplicationController
  CONSUMER_KEY='pJ2F7coxlc5jlKcmSPrLqQ';
  CONSUMER_SECRET='n0qURhYbR8ugJfET12fhb1ko4vJD18e8Kmuxlk3M884'
  CALLBACK_PATH="/index/oauth_callback"
  protect_from_forgery :except=>[:index]
  def consumer
    OAuth::Consumer.new(CONSUMER_KEY,CONSUMER_SECRET,{site:"http://twitter.com"})
  end
  Twitter.configure do |config|
    config.consumer_key=CONSUMER_KEY
    config.consumer_secret=CONSUMER_SECRET
  end
  def hoge
    #Thread.new{
      p "STARTHOGE"
      http=HTTPPost 'google.com',80,'/search?q=test',{x:1,y:'a',z:1023}
      p "ENDHOGE"
    #}
    render json:'hoge'
  end
  def index
    render locals:{screens:Screen.getSorted(100)}
  end
  def embed
    render layout:false,locals:{url:params[:url]}
  end
  def screen
    render locals:{url:params[:url]}
  end


  def authorized?
    session[:oauth_token]
  end
  def logout
    session.delete :oauth_token
    render text:'logout'
  end
  def twitter
    Twitter::Client.new session[:oauth_token]
  end
  def tweet
    if request[:id]
      render json:(twitter.update request[:id])
    else
      userinfo=twitter.user
      render json:session[:user]
    end
  end
  def login
    if authorized?
      render text:'authorized'
      session.delete :oauth_token
      return
    end
    request_token=consumer.get_request_token(oauth_callback:"http://#{request.host_with_port+CALLBACK_PATH}")
    p request_token
    session[:request_token]={token:request_token.token,secret:request_token.secret}
    redirect_to request_token.authorize_url
  end
  def oauth_callback
    if !authorized?
      reqtoken=session[:request_token]
      request_token=OAuth::RequestToken.new(consumer,reqtoken[:token],reqtoken[:secret])
      access_token=request_token.get_access_token({},oauth_token:params[:oauth_token],oauth_verifier:params[:oauth_verifier])
      session.delete :request_token
      session[:oauth_token]={oauth_token:access_token.token,oauth_token_secret:access_token.secret}
      info=twitter.user
      session[:user]={id:info.id,profile_image:info.profile_image_url,screen_name:info.screen_name,name:info.name||info.screen_name}
    end
    redirect_to :action=>:index
  end
end
