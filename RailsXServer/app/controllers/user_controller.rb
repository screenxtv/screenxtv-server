class UserController < ApplicationController
	def new
    
    
	end

  def login
    user=auth_user
    session[:user_id]=user.id
  end

  def logout
    session.delete :user_id
  end

  def create
    user=User.create_account(params)
    redirect_to :index
  end

  def index
    @user=current_user
    redirect_to :login if @user.nil?
  end

  def update


  end
end
