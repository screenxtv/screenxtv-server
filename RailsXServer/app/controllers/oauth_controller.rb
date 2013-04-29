class OauthController < ApplicationController

  def callback
    auth = request.env["omniauth.auth"]
    render nothing:true and return unless auth
    provider = auth[:provider]
    oauth_info = {
      provider: provider,
      uid: auth[:uid],
      name: auth[:info][:nickname],
      icon: auth[:info][:image],
      display_name: auth[:info][:name],
      token: auth[:credentials][:token],
      secret: auth[:credentials][:secret],
    }
    user = User.find_by_oauth(oauth_info)
    if user
      build_user_session user
    elsif current_user
      current_user.connect_with oauth_info
      build_user_session current_user
    else
      session[:oauth] ||= {}
      session[:oauth][provider] = oauth_info
      session[:oauth][:main] = provider
    end
    render layout:false
  end

  def switch
    render nothing:true and return unless session[:oauth]
    provider = params[:provider]
    session[:oauth][:main] = provider if social_info.has_key? provider
    render json:social_info
  end
end
