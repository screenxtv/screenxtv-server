class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :user_signed_in?, :current_user, :social_info

  Twitter.configure do |config|
    info=OAuthConsumers['twitter']
    config.consumer_key=info[:consumer_key]
    config.consumer_secret=info[:consumer_secret]
  end

  def destroy_user_session
    @current_user = nil
    session.delete :user_id
    session.delete :oauth
  end

  def build_user_session user
    @current_user     = user
    session[:user_id] = user.id
    session[:oauth]   = {main: :user}
    user.oauths.each do |oauth|
     session[:oauth][oauth.provider] = oauth.session_hash
    end
  end

  def build_oauth_session oauth
    provider = oauth[:provider]
    session[:oauth] ||= {}
    session[:oauth][provider] = oauth
    session[:oauth][:main] = provider
  end

  def switch_oauth_session provider
    session[:oauth] ||= {}
    if user_signed_in?
      session[:oauth][:main] = :user
    elsif social_info.has_key? provider
      session[:oauth][:main] = provider
    else
      session[:oauth][:main] = 'anonymous'
    end
    @social_info = nil
  end

  def connect_and_build_user_session user
    if session[:oauth]
      OAuthConsumers.keys.each do |provider|
        info = session[:oauth][provider]
        user.oauth_connect info if info
      end
    end
    build_user_session user
  end

  def current_user
    if @current_user.nil? && session[:user_id]
      @current_user = User.where(id: session[:user_id]).first if session[:user_id]
      destroy_user_session unless @current_user
    end
    @current_user
  end

  def already_signed_in!
    redirect_to users_index_path if user_signed_in?
  end

  def nodejs_filter
    render nothing: true unless ["127.0.0.1", "0.0.0.0"].include? request.remote_ip
  end

  def user_signed_in!
    redirect_to users_sign_in_path unless user_signed_in?
  end

  def user_signed_in?
    current_user.present?
  end

  def social_info
    return @social_info if @social_info
    @social_info = {}
    if session[:oauth]
      OAuthConsumers.keys.each do |provider|
        @social_info[provider] = session[:oauth][provider].slice :name, :display_name, :icon, :provider if session[:oauth][provider]
      end
      @social_info[:main] = session[:oauth][:main]
    end
    @social_info[:main] ||= 'anonymous'
    begin
      icon_id = current_user.try(:id) || request.session_options[:id][0, 4].hex
    rescue
      icon_id = 0
    end
    @social_info['anonymous'] = {
      icon: "/assets/icon/#{icon_id % 32}.png"
    }
    if user_signed_in?
      @social_info[:user] = {
        name: current_user.name,
        display_name: current_user.nickname,
        icon: current_user.user_icon
      }
      @social_info[:main] = :user
    end
    @social_info
  end



  def twitter_post_to_user text
    oauth = session[:oauth]['twitter']
    if oauth
      token = {oauth_token: oauth[:token], oauth_token_secret: oauth[:secret]}
      twitter_post_token_text token, text
    end
  end
  def twitter_post_to_news text
    twitter_post_token_text TWITTER_NEWS, text
  end

  def render_404
    render file: "#{Rails.root}/public/404", layout: false, status: 404
  end

  private
  def twitter_post_token_text token, text
    Twitter::Client.new(token).update text
  end

end
