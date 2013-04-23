class OauthController < ApplicationController
  CALLBACK_PATH="/oauth/callback"
  def connect
    provider=params[:provider]
    request_token=consumer(provider).get_request_token(oauth_callback:"http://#{request.host_with_port+CALLBACK_PATH}")
    session[:connect_info]={provider:provider,token:request_token.token,secret:request_token.secret}
    redirect_to request_token.authorize_url
  end
  def disconnect
    session.delete :oauth
    render nothing:true
  end

  def callback
    connect_info=session[:connect_info]
    session.delete :connect_info
    provider=connect_info[:provider]
    render nothing:true and return unless connect_info
    request_token=OAuth::RequestToken.new(consumer(connect_info[:provider]),connect_info[:token],connect_info[:secret])
    access_token=request_token.get_access_token({},oauth_token:params[:oauth_token],oauth_verifier:params[:oauth_verifier])
    oauth_user=oauth_info provider, access_token
    render nothing:true and return unless oauth_user
    session[:oauth]||={}
    session[:oauth][:main]=session[:oauth][provider]=oauth_user
    user=User.oauth_authenticate oauth_user
    session[:user_id]=user.id if user
    render layout:false
  end


  def oauth_info provider,access_token
    self.send "oauth_info_#{provider}", provider, access_token
  end

  def oauth_info_twitter provider, access_token
    user = twitter(oauth_token:access_token.token,oauth_token_secret:access_token.secret).user
    return nil unless user
    {
      provider: provider,
      uid: user.id,
      token: access_token.token,
      secret: access_token.secret,
      name: user.screen_name,
      display_name: user.name || user.screen_name,
      icon: user.profile_image_url
    }
  end
end
