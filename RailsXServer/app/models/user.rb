class User < ActiveRecord::Base
  attr_accessible :name, :display_name, :email, :password, :icon
  attr_accessor :password
  has_many :screens, dependent: :destroy
  has_many :oauths, dependent: :destroy
  validates_format_of :name, with:/^[_a-zA-Z0-9]{4,}$/
  validates_uniqueness_of :name
  validates_format_of :email, with:/^[a-zA-Z0-9_-][a-zA-Z0-9\._-]*@[a-zA-Z0-9_-][a-zA-Z0-9\._-]*$/
  validates_presence_of :password_digest

  # User.create(name: 'hogehoge')
  # u = User.new(name: 'hogehoge')
  # u.valid?
  # u.errors[:name] # => ['error', 'messages']

  def self.digest(password)
    Digest::SHA2.hexdigest(password)
  end
  def self.find_by_oauth(oauth)
    Oauth.where(provider:oauth[:provider],uid:oauth[:uid]).first.try :user
  end
  def self.find_by_password(name_or_email,password)
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
  def connect_with oauth
    oauths.where(provider:oauth[:provider]).create_or_update(oauth)
    self.display_name ||= oauth.display_name
    self.icon ||= oauth.icon
  end
  def oauth_disconnect provider
    oauths.where(provider:provider).destroy
  end
end
