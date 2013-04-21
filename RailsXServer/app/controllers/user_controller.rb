class UserController < ApplicationController
  def signin
    redirect_to user_index_path and return if user_signed_in?
    user=User.authenticate params[:name_or_email],params[:password]
    if user
      session[:user_id]=user.id if user
      redirect_to action:'index'
    else
      @signin_error=true
      render 'signin'
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
