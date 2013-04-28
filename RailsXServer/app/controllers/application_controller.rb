class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :user_signed_in?,:current_user,:social_info

  Twitter.configure do |config|
    info=OAuthConsumers['twitter']
    config.consumer_key=info[:consumer_key]
    config.consumer_secret=info[:consumer_secret]
  end

  def current_user_icon
    if social_info
      social_info[:icon]
    else
      n=session[:user_id] || request.session_options[:id][0,4].hex
      "/assets/icon/#{n%32}.png"
    end
  end
  def current_user_name
    if user_signed_in?
      current_user.name
    else
      social_info[:name] if social_info
    end
  end
  def current_user
    uid=session[:user_id]
    if uid
      user=User.where(id:uid).first
      session.delete :user_id if user.nil?
      user
    end
  end
  def user_signed_in!
    redirect_to user_signin_path unless user_signed_in?
  end
  def user_signed_in?
    session[:user_id]!=nil&&current_user!=nil
  end
  def social_info
    info={}
    if session[:oauth]
      session[:oauth].each do|social,data|
        info[social]=data.slice(:name,:display_name,:icon) if social!=:main
      end
      info[:main]=session[:oauth][:main]
    end
    info
  end
  def twitter(token=nil)
    Twitter::Client.new token||session[:oauth_twitter][:token]
  end
  def news_twitter
    Twitter::Client.new TWITTER_NEWS
  end
end
