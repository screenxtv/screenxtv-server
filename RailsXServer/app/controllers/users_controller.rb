class UsersController < ApplicationController
  before_filter :user_signed_in!, only: [:index, :update, :sign_out]
  before_filter :already_signed_in!, only: [:sign_in, :sign_up]
  def already_signed_in!
    redirect_to users_index_path if user_signed_in?
  end

  def sign_in
    if params[:sign_in]
      user = User.find_by_password params[:sign_in][:name_or_email], params[:sign_in][:password]
      if user
        connect_and_build_user_session user
        redirect_to action:'index'
      else
        @sign_in_error = 'wrong username, email or password'
      end
    end
  end

  def sign_up
    user=User.new_account(params[:sign_up])
    begin
      save_status = user.save
    rescue
      @reserve_error = "Error: cannot reserve your url: #{user.name}" if Screen.where(url:user.name).exists?
    end
    if save_status
      connect_and_build_user_session user
      redirect_to action:'index'
    else
      @sign_up_errors = user.errors
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
    
    OAuthConsumers.keys.each do |provider|
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
    @user = User.where(name:params[:name]).first
    render_404 unless @user
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
