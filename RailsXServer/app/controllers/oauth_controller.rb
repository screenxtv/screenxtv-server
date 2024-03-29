class OauthController < ApplicationController

  def auth_popup
    session[:callback_mode] = :popup
    redirect_to "/auth/#{params[:provider]}"
  end

  def auth_normal
    session[:callback_mode] = :normal
    redirect_to "/auth/#{params[:provider]}"
  end

  def callback
    auth = request.env["omniauth.auth"]
    render nothing: true and return unless auth
    oauth_info = {
      provider: auth[:provider],
      uid: auth[:uid],
      name: auth[:info][:nickname],
      icon: auth[:info][:image],
      display_name: auth[:info][:name],
      token: auth[:credentials][:token],
      secret: auth[:credentials][:secret]
    }
    build_oauth_session oauth_info
    user = User.find_by_oauth(oauth_info) || current_user
    connect_and_build_user_session user if user

    if session[:callback_mode] == :popup
      render layout: false
    elsif user
      redirect_to users_index_path 
    else
      redirect_to users_sign_in_path
    end
    session.delete :callback_mode
  end

  def switch
    switch_oauth_session params[:provider]
    render json: social_info
  end

  def disconnect
    render nothing: true and return unless user_signed_in?
    current_user.oauth_disconnect params[:provider]
    build_user_session current_user
    redirect_to users_index_path
  end
end
