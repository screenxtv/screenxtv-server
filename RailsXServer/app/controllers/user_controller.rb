class UserController < ApplicationController
  def signin
    user=User.authenticate params[:name],params[:password]
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
    redirect_to action:'index'
  end

  def create
    user=User.create_account(params)
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
