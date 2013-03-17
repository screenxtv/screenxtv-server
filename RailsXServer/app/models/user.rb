class User < ActiveRecord::Base
  has_many :screens,dependent: :destroy
  validates_format_of :name,with:/^[_a-zA-Z0-9]{4,}$/
  validates_format_of :email,with:/^[a-zA-Z0-9]+[a-zA-Z0-9\._-]*@[a-zA-Z0-9_-]+[a-zA-Z0-9\._-]+$/

  def self.digest(password)
    Digest::SHA2.hexdigest(password)
  end
  def self.authenticate(name_or_email,password)
    if name_or_email&&password
      pswd=digest(password)
      if name_or_email.include? '@'
        User.where(email:name_or_email,password_digest:pswd).first
      else
        User.where(name:name_or_email,password_digest:pswd).first
      end
    end
  end
  def check_password(password)
    password_digest==User.digest(password)
  end
  def self.create_account(params)
    user=User.new()
    user.name=params[:name]
    user.email=params[:email]
    return nil if not params[:password].match /^[\x21-\x7e]+$/
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
