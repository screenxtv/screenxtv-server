class IndexController < ApplicationController
  def index
    render locals:{screens:Screen.getSorted(100)}
  end

  def howto
    @title='Install'
  end

  def embed
    @title=params[:url]
    render layout:false,locals:{url:params[:url],link:params[:link]}
  end

  def screen
    @title=params[:url]
    render locals:{url:params[:url],user:(authorized? ? session[:user] : nil)}
  end

  def logout
    session.delete :oauth_token
    session.delete :user
    redirect_to :action=>:index
  end

  def login
    if authorized?
      redirect_to :action=>:index
    else
      request_token=consumer.get_request_token(oauth_callback:"http://#{request.host_with_port+CALLBACK_PATH}")
      session[:request_token]={token:request_token.token,secret:request_token.secret}
      redirect_to request_token.authorize_url
    end
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
