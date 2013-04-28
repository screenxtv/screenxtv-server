class UserController < ApplicationController
  before_filter :user_signed_in!, only: [:index, :update, :signout]
  before_filter :already_signed_in, only: [:signin, :create]
  def already_signed_in
    redirect_to user_index_path if user_signed_in?
  end
  
  def signin
    user=User.find_by_password params[:name_or_email],params[:password]
    if user
      session[:user_id]=user.id
      redirect_to action:'index'
    else
      @signin_error='wrong password'
      render 'signin'
    end
  end

  def update
    current_user.name = params[:name] if params[:name]
    current_user.name = params[:display_name] if params[:display_name]
    current_user.email = params[:email] if params[:email]
    OAuthConstants::PROVIDERS.each do |provider|
      case(provider)
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


  def signout
    session.delete :user_id
    redirect_to '/'
  end

  def create
    @params=params
    user=User.create_account(params[:signup])
    if user
      session[:user_id]=user.id
      redirect_to action:'index'
    else
      @create_error=true
      render 'signin'
    end
  end

  def index
    if user_signed_in?
      render 'index'
    else
      render 'signin'
    end
  end
end
