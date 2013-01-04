class OauthController < ApplicationController
  CALLBACK_PATH="/oauth/callback"
  def connect
    request_token=consumer.get_request_token(oauth_callback:"http://#{request.host_with_port+CALLBACK_PATH}")
    session[:request_token]={token:request_token.token,secret:request_token.secret}
    redirect_to request_token.authorize_url
  end
  def disconnect
    session.delete :oauth
    render nothing:true
  end
  def callback
    reqtoken=session[:request_token]
    if reqtoken
      request_token=OAuth::RequestToken.new(consumer,reqtoken[:token],reqtoken[:secret])
      access_token=request_token.get_access_token({},oauth_token:params[:oauth_token],oauth_verifier:params[:oauth_verifier])
      session.delete :request_token
      token={oauth_token:access_token.token,oauth_token_secret:access_token.secret}
      info=twitter(token).user
    end
    if info
      @info={name:info.name||info.screen_name,icon:info.profile_image_url}
      session[:oauth]={id:info.id,token:token,info:@info}
    end
    render layout:false
  end
end