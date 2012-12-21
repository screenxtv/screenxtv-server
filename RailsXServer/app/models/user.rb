class User < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :screens,dependent: :destroy
  def self.digest(password)
    Digest::SHA2.hexdigest(password)
  end
  def self.authenticate(name,password)
    return if name.nil? || password.nil?
    User.where({name:name,password_digest:digest(password)}).first
  end
  def check_password(password)
    password_digest==digest(password)
  end
  def self.create_account(params)
    user=User.new()
    user.name=params[:username]
    user.email=params[:email]
    user.password_digest=digest params[:password]
    user.auth_key=digest "#{params[:username]}#{params[:password]}#{rand}"
    begin
      user.save!
      user.screens.create(url:user.name)
      user
    rescue
    end
  end
end
