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
      current_user.oauth_connect oauth_info
      build_user_session current_user
    else
      session[:oauth] ||= {}
      session[:oauth][provider] = oauth_info
      session[:oauth][:main] = provider
    end
    if params.has_key?(:popup)
      render layout:false
    else
      redirect_to users_index_path 
    end
  end

  def switch
    render nothing:true and return unless session[:oauth]
    unless current_user
      provider = params[:provider]
      session[:oauth][:main] = provider if social_info.has_key? provider
    end
    render json:social_info
  end

  def disconnect
    render nothing:true and return unless user_signed_in?
    current_user.oauth_disconnect params[:provider]
    build_user_session current_user
    redirect_to users_index_path
  end
end
