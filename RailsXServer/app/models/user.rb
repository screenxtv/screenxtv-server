class User < ActiveRecord::Base
  attr_accessible :name,:email,:password
  attr_accessor :password
  has_many :screens,dependent: :destroy
  validates_format_of :name,with:/^[_a-zA-Z0-9]{4,}$/
  validates_format_of :email,with:/^[a-zA-Z0-9_-][a-zA-Z0-9\._-]*@[a-zA-Z0-9_-][a-zA-Z0-9\._-]*$/
  validates_presence_of :password_digest

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
  def check_password password
    password_digest == User.digest(password)
  end
  def password= password
    if password.try(:match,/^[\x21-\x7e]{4,}$/)
      self.password_digest = User.digest password
    else
      self.password_digest = ''
    end
    self.auth_key = User.digest "#{self.name}#{self.password}#{rand}"
  end
  def self.create_account(params)
    user=User.new(params)
    user.screens.new(url:user.name)
    begin
      user.save!
      user
    rescue
    end
  end
end
