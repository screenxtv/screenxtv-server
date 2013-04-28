class OauthController < ApplicationController
  CALLBACK_PATH="/oauth/callback"

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
    
    session[:oauth] ||= {}
    provider = oauth_user[:provider]
    session[:oauth][provider] = oauth_user
    user=User.find_by_oauth oauth_user
    session[:user_id]=user.id if user
    render layout:false
  end

  def destroy
    session[:oauth].delete params[:provider]
  end
end
