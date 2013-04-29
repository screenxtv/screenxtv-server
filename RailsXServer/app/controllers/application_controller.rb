class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :user_signed_in?,:current_user,:social_info

  Twitter.configure do |config|
    info=OAuthConsumers['twitter']
    config.consumer_key=info[:consumer_key]
    config.consumer_secret=info[:consumer_secret]
  end

  def current_social_user
    social_info[social_info[:main]]
  end
  
  def destroy_user_session
    @current_user = nil
    session.delete :user_id
    session.delete :oauth
  end

  def auth_info_hash_for obj
    keys = [:provider,:uid,:name,:icon,:display_name,:token,:secret]
    hash = {}
      keys.each do |key|
        hash[key] = obj[key]
      end
    hash
  end

  def build_user_session user
    @current_user = user
    session[:user_id] = user.id
    session[:oauth] = {}
    user.oauths.each do |oauth|
      session[:oauth][oauth.provider] = auth_info_hash_for oauth
    end
    session[:oauth][:main] = 'user'
  end

  def current_user
    user_id= session[:user_id]
    if @current_user.nil? && user_id
      @current_user = User.where(id:user_id).first
      session.delete :user_id if @current_user.nil?
    end
    @current_user
  end

  def user_signed_in!
    redirect_to user_signin_path unless user_signed_in?
  end

  def user_signed_in?
    current_user.present?
  end

  def social_info
    return @social_info if @social_info
    @social_info={}
    if user_signed_in?
      @social_info[:user] = {
        name: current_user.name,
        display_name: current_user.display_name || current_user.name,
        icon: current_user.icon || image_url("icon/#{current_user.id % 32}.png")
      }
      @social_info[:main] = :user
    else
      if session[:oauth]
        OAuthConsumers.keys.each do |provider|
          @social_info[provider] = session[:oauth][provider].slice :name, :display_name, :icon
        end
        @social_info[:main] = session[:oauth][:main]
      else
        @social_info[:main]='anonymous'
      end
      @social_info['anonymous'] = {
        icon: image_url"/assets/icon/#{request.session_options[:id][0,4].hex%32}.png"
      }
    end
    @social_info
  end

  def twitter(token=nil)
    Twitter::Client.new token||session[:oauth_twitter][:token]
  end

  def news_twitter
    Twitter::Client.new TWITTER_NEWS
  end

end
