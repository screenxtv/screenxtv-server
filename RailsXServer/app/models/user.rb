class User < ActiveRecord::Base
  has_many :screens,dependent: :destroy

  def self.digest(password)
    Digest::SHA2.hexdigest(password)
  end
  def self.authenticate(name,password)
    if name&&password 
      User.where({name:name,password_digest:digest(password)}).first
    end
  end
  def check_password(password)
    password_digest==User.digest(password)
  end
  def self.create_account(params)
    user=User.new()
    user.name=params[:name]
    user.email=params[:email]

    return nil if !user.name.match(/^[_a-zA-Z0-9]{4,}$/)
    return nil if !user.email.match(/^[a-zA-Z0-9]+[a-zA-Z0-9\._-]*@[a-zA-Z0-9_-]+[a-zA-Z0-9\._-]+$/)

    user.password_digest=digest params[:password]
    user.auth_key=digest "#{params[:name]}#{params[:password]}#{rand}"
    begin
      user.save!
      user.screens.create(url:user.name)
      user
    rescue
      user.destroy
    end
  end
end
