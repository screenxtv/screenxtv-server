class UserController < ApplicationController
  def login
    user=User.authenticate
    session[:user_id]=user.id
    redirect_to :index
  end

  def logout
    session.delete :user_id
  end

  def new
    @user=User.new
  end

  def create
    if User.create_account(params)
      redirect_to :index
    else
      render text:'error'
    end
  end

  def index
    @user=current_user
    if @user
      render 'index'
    else
      render 'login'
    end
  end
end
