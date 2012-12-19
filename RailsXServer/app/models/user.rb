class User < ActiveRecord::Base
  # attr_accessible :title, :body
  def auth_user(params)
  	User.where{name:params[:name],password_digest:digest params[:password]}.first
  end
  def digest(password)
  	Digest::SHA2.hexdigest(password)
  end
  def create_account(params)
  	user=User.new()
    user.name=params[:name]
    user.email=prams[:email]
    user.password_digest=digest params[:password]
    user.auth_key=digest "#{params[:password]}#{params[:name]}#{rand}"
    user.save
  end

end
