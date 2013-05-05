class UsersController < ApplicationController
  before_filter :user_signed_in!, except: [:sign_in, :sign_up, :show]
  before_filter :already_signed_in!, only: [:sign_in, :sign_up]
  def already_signed_in!
    redirect_to users_index_path if user_signed_in?
  end

  def sign_in
    render and return unless request.post?
    if params[:sign_in]
      user = User.find_by_password params[:sign_in][:name_or_email], params[:sign_in][:password]
    end
    if user
      connect_and_build_user_session user
      redirect_to users_index_path
    else
      @sign_in_error = 'wrong username, email or password'
    end
  end

  def sign_up
    render 'sign_in' and return unless request.post?
    user=User.new_account(params[:sign_up])
    if user.save
      connect_and_build_user_session user
      redirect_to action:'index'
    else
      @sign_up_user = user
      @sign_up_errors = user.errors
      if [:name,:email,:password].all?{|key|@sign_up_errors[key].empty?}
        @reserve_error = true
      end
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
  end

  def edit
  end

  def create_screen
    if current_user.screens.count < Screen::USER_MAX_SCREENS
      current_user.screens << Screen.new(url:params[:url]);
      current_user.save
    end
    redirect_to users_index_path
  end

  def change_screen
    screen = current_user.screens.where(url:params[:url]).first
    screen.update_attributes(url:params[:new_url]) if screen
    redirect_to users_index_path
  end

  def destroy_screen
    if params[:url_confirm]==params[:url]
      screen = current_user.screens.where(url:params[:url]).first
      screen.destroy if screen
    end
    redirect_to users_index_path
  end

  def show
    @user = User.where(name:params[:name]).first
    render_404 unless @user
  end

end
