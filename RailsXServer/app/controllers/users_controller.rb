class UserController < ApplicationController
  before_filter :user_signed_in!, only: [:index, :update, :sign_out]
  before_filter :already_signed_in!, only: [:sign_in, :sign_up]
  def already_signed_in!
    redirect_to user_index_path if user_signed_in?
  end

  def sign_in
    user = User.find_by_password params[:name_or_email], params[:password]
    if user
      connect_and_build_user_session user
      redirect_to action:'index'
    else
      flash[:notice] = 'wrong username, email or password'
      render 'sign_in'
    end
  end

  def sign_up
    @params=params
    user=User.create_account(params[:signup])
    if user
      connect_and_build_user_session user
      redirect_to action:'index'
    else
      @create_error=true
      render 'sign_in'
    end
  end

  def sign_out
    destroy_user_session
    redirect_to '/'
  end

  def update
    current_user.name = params[:name] if params[:name]
    current_user.display_name = params[:display_name] if params[:display_name]
    current_user.email = params[:email] if params[:email]
    if params[:disconnect]
    OAuthConsumers.keys.each do |provider|
        when 'true'
          oauth = session[:oauth][provider]
          current_user.connect_with oauth
        when 'false'
          current_user.disconnect_with provider
      end
    end
    provider = params[:provider]
    info = session["oauth_#{provider}"]
    if info

    end
  end

  def index
    if user_signed_in?
      render 'index'
    else
      render 'sign_in'
    end
  end

  def show
    @user = User.find(name:params[:name])
  end

  def connect_and_build_user_session user
    if session[:oauth]
      OAuthConsumers.keys.each do |provider|
        info = session[:oauth][provider]
        user.connect_with if info
      end
    end
    build_user_session user
  end

end
