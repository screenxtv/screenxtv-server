class Chat < ActiveRecord::Base
  attr_accessible :name,:icon,:message,:url
  belongs_to :screen
  def as_json
    {name:name,icon:icon,url:url,message:message,time:created_at.to_i}
  end
  def to_json
    as_json.to_json
  end
end
