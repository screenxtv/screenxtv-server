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
    auth = request.env["omniauth.auth"]
    render nothing:true and return unless auth
    oauth_user = {
      provider: auth[:provider],
      uid: auth[:uid],
      name: auth[:info][:nickname],
      icon: auth[:info][:image],
      display_name: auth[:info][:name],
      token: auth[:credentials][:token],
      secret: auth[:credentials][:secret],
    }
    session[:oauth]||={}
    session[:oauth][:main]=session[:oauth][oauth_user[:provider]]=oauth_user
    user=User.oauth_authenticate oauth_user
    session[:user_id]=user.id if user
    render layout:false
  end

  def consumer provider
    info=OAuthConsumers[provider]
    OAuth::Consumer.new(info[:consumer_key],info[:consumer_secret],{site:info[:site]})
  end
end
