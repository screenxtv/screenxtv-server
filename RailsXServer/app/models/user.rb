class User < ActiveRecord::Base
  # attr_accessible :title, :body
  def self.digest(password)
    Digest::SHA2.hexdigest(password)
  end
  def self.authenticate(name,password)
    User.where({name:params[:name],password_digest:digest(params[:password])}).first
  end
  def check_password(password)
    password_digest==digest(password)
  end
  def self.create_account(params)
    user=User.new()
    user.name=params[:name]
    user.email=prams[:email]
    user.password_digest=digest params[:password]
    user.auth_key=digest "#{params[:password]}#{params[:name]}#{rand}"
    user if user.save
  end
end
