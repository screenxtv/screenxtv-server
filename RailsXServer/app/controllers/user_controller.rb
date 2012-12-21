class UserController < ApplicationController
  def signin
    user=User.authenticate params[:username],params[:password]
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

  def new
    @user=User.new
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
    @user=current_user
    if @user
      render 'index'
    else
      render 'signin'
    end
  end
end
