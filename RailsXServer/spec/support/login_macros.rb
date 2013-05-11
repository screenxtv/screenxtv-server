module LoginMacros

  def do_login user
    session[:user_id] = user.id
    session[:oauth]   = {main: :user}
    user.oauths.each do |oauth|
     session[:oauth][oauth.provider] = oauth.session_hash
    end
  end

  def do_oauth oauth
    provider = oauth[:provider]
    session[:oauth] ||= {}
    session[:oauth][provider] = oauth
    session[:oauth][:main] = provider
  end

  def user_signed_in?
    session[:user_id].present?
  end

  def do_logout
    session.delete :user_id
    session.delete :oauth
  end

end