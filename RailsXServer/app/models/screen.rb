class Screen < ActiveRecord::Base
  attr_accessible :url,:total_viewer,:max_viewer,:total_time,:last_cast,:state,
    :current_time,:current_viewer,:current_max_viewer,:current_total_viewer,
    :pause_count,:title,:color,:vt100
  belongs_to :user
  has_many :chats, dependent: :destroy
  validates :url, length:{minimum:4, maximum:16}, uniqueness:true, format:/^[_a-zA-Z0-9]*$/

  USER_MAX_SCREENS = 5
  STATE_CASTING = 2
  STATE_PAUSED = 1
  STATE_NONE = 0

  def info
    {
      total_viewer:total_viewer,
      max_viewer:max_viewer,
      total_time:total_time
    }
  end
  def casting?
    state==STATE_CASTING
  end
  def self.notify(params)
    screen=Screen.where(url:params[:url]).first;
    case params[:status]
    when 'terminate'
      screen.terminate if screen
      return false
    when 'update'
      params[:state]=STATE_CASTING
    when 'castend'
      params[:state]=STATE_PAUSED
    end
    params[:last_cast]=Time.now
    if !screen
      screen=Screen.create(params)
      true
    else
      state=screen.state
      screen.update_attributes params.slice *screen.attribute_names.map(&:to_sym)
      state==STATE_NONE
    end
  end
  def chats_for_js
    chats.map{|c|{name:c.name,icon:c.icon,message:c.message,time:c.created_at.to_i}}
  end
  def terminate
    if user
      update_attributes(
          state:STATE_NONE,
          title:nil,color:nil,vt100:nil,
          current_viewer:0,current_max_viewer:0,current_total_viewer:0,
          current_time:0,pause_count:0
        )
    else
      destroy
    end
  end
  def self.cleanup
    range=0x10000.days.ago..10.minutes.ago
    Screen.where(state:[TATE_PAUSED,TATE_CASTING],updated_at:range).each(&:terminate)
  end
  def self.getSorted(limit)
    cleanup
    screens=Arel::Table.new :screens
    arrcasting=Screen.where(state:TATE_CASTING).order(screens[:pause_count],screens[:current_viewer].desc).limit(limit);
    if arrcasting.count<limit
      arrcasted=Screen.where(state:STATE_PAUSED).limit(limit-arrcasting.count)
    else
      arrcasted=[]
    end
    arrcasting+arrcasted
  end
  def to_json
    ("{"+"\"url\":"+url.to_json+","+
    "\"title\":"+title.to_json+","+
    "\"color\":"+color.to_json+","+
    "\"viewer\":"+current_viewer.to_s+","+
    "\"casting\":"+(state==STATE_CASTING).to_s+","+
    "\"vt100\":"+vt100+"}").gsub("<","\\u003c").gsub(">","\\u003e");
  end
end
