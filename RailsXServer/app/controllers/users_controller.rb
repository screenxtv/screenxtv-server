class UsersController < ApplicationController
  protect_from_forgery except: [:authenticate]
  before_filter :nodejs_filter, only: [:authenticate]
  before_filter :user_signed_in!, except: [:authenticate, :sign_in, :sign_up, :show]
  before_filter :already_signed_in!, only: [:sign_in, :sign_up]

  def authenticate
    user=User.where(name: params[:user]).first
    if user && user.check_password(params[:password])
      render json: {auth_key: user.auth_key}
    else
      render json: {error: 'wrong user or password'}
    end
  end

  def sign_in
    render and return unless request.post?
    if params[:sign_in]
      user = User.find_by_password params[:sign_in][:name_or_email], params[:sign_in][:password]
    end
    if user
      connect_and_build_user_session user
      redirect_to action: :index
    else
      @sign_in_error = 'wrong username, email or password'
    end
  end

  def sign_up
    render 'sign_in' and return unless request.post?
    user=User.new params[:sign_up]
    if user.save
      connect_and_build_user_session user
      redirect_to action: :index
    else
      @sign_up_user = user
      @sign_up_errors = user.errors
      if [:name, :email, :password_digest].all?{|key|@sign_up_errors[key].empty?}
        @reserve_error = true
      end
      render 'sign_in'
    end
  end

  def sign_out
    destroy_user_session
    redirect_to root_path
  end

  def index
  end

  def update
    current_user.display_name = params[:display_name] if params[:display_name]
    current_user.email = params[:email] if params[:email]
    social = social_info[params[:social_icon]]
    current_user.icon = social[:icon] if social
    flash[:notice] = current_user.errors.full_messages.join "<br>" unless current_user.save
    redirect_to action: :index
  end

  # def create_screen
  #   if current_user.screens.count < Screen::USER_MAX_SCREENS
  #     current_user.screens << Screen.new(url:params[:url]);
  #     current_user.save
  #   end
  #   redirect_to users_index_path
  # end

  def change_screen
    screen = current_user.screens.where(url:params[:url]).first
    screen.update_attributes(hash_tag:params[:hash_tag]) if screen
    redirect_to users_index_path
  end

  # def destroy_screen
  #   if params[:url_confirm]==params[:url]
  #     screen = current_user.screens.where(url:params[:url]).first
  #     screen.destroy if screen
  #   end
  #   redirect_to users_index_path
  # end

  def show
    @user = User.where(name: params[:name]).first
    render_404 unless @user
  end

end
