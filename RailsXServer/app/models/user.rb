class User < ActiveRecord::Base
  attr_accessible :name, :display_name, :email, :password, :icon
  attr_accessor :password
  has_many :screens, dependent: :destroy
  has_many :oauths, dependent: :destroy
  validates :name, length:{minimum:4, maximum:16}, uniqueness:true, format:/^[_a-zA-Z0-9]*$/
  validates :email, uniqueness:true, format:/^[a-zA-Z0-9_-][a-zA-Z0-9\._-]*@[a-zA-Z0-9_-][a-zA-Z0-9\._-]*$/
  validates_presence_of :password_digest

  before_validation do
    self.screens.new url:self.name if id.nil?
  end

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
    if password.try(:match,/^[\x21-\x7e]{4,16}$/)
      self.password_digest = User.digest password
    else
      self.password_digest = nil
    end
    self.auth_key = User.digest "#{self.name}#{self.password}#{rand}"
  end

  def oauth_connect oauth_info
    oauth = oauths.where(provider:oauth_info[:provider]).first_or_initialize
    oauth.update_attributes oauth_info
    self.display_name ||= oauth.display_name
    self.icon ||= oauth.icon
    save
  end

  def oauth_disconnect provider
    oauths.where(provider:provider).destroy_all
  end

  def user_icon
    icon || "/assets/icon/#{id % 32}.png"
  end

end

