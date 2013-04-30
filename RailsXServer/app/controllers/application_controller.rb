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

  def build_user_session user
    @current_user = user
    session[:user_id] = user.id
    session[:oauth] = {}
    user.oauths.each do |oauth|
      keys = [:provider,:uid,:name,:icon,:display_name,:token,:secret]
      hash = {}
      keys.each do |key|
        hash[key] = oauth[key]
      end
      session[:oauth][oauth.provider] = hash
    end
    session[:oauth][:main] = 'user'
  end

  def current_user
    @current_user ||= User.where(id:session[:user_id]).first if session[:user_id]
    destroy_user_session unless @current_user
    @current_user
  end

  def user_signed_in!
    redirect_to users_sign_in_path unless user_signed_in?
  end

  def user_signed_in?
    current_user.present?
  end

  def social_info
    @social_info={}
    if session[:oauth]
      OAuthConsumers.keys.each do |provider|
        @social_info[provider] = session[:oauth][provider].slice :name, :display_name, :icon if session[:oauth][provider]
      end
      @social_info[:main] = session[:oauth][:main]
    else
      @social_info[:main]='anonymous'
    end
    @social_info['anonymous'] = {
      icon: view_context.image_path("/assets/icon/#{request.session_options[:id][0,4].hex%32}.png")
    }
    if user_signed_in?
      @social_info[:user] = {
        name: current_user.name,
        display_name: current_user.display_name || current_user.name,
        icon: current_user.icon || view_context.image_path("icon/#{current_user.id % 32}.png")
      }
      @social_info[:main] = :user
    end
    @social_info
  end

  def twitter(token=nil)
    if token.nil?
      oauth = session[:oauth]['twitter']
      token = {consumer_key:oauth[:token],consumer_secret:oauth[:secret]} if oauth
    end
    Twitter::Client.new token if token
  end

  def news_twitter
    twitter TWITTER_NEWS
  end

  def render_404
    render file:"#{Rails.root}/public/404", layout:false, status:404
  end
end
