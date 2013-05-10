class Screen < ActiveRecord::Base
  attr_accessible :url,:total_viewer,:max_viewer,:total_time,:cast_count,:last_cast,:state,
    :current_time,:current_viewer,:current_max_viewer,:current_total_viewer,
    :pause_count,:title,:color,:vt100
  belongs_to :user
  has_many :chats, dependent: :destroy
  validates :url, length:{minimum:2, maximum:16}, uniqueness:true, format:/^[_a-zA-Z0-9]*$/

  USER_MAX_SCREENS = 3
  STATE_CASTING = 2
  STATE_PAUSED = 1
  STATE_NONE = 0

  def info
    {
      total_viewer:total_viewer,
      max_viewer:max_viewer,
      total_time:total_time,
      cast_count:cast_count
    }
  end

  def casting?
    state==STATE_CASTING
  end

  def self.notify(params)
    screen=Screen.where(url:params[:url]).first;
    if params[:state]==STATE_NONE
      Screen.where(url:params[:url]).first.try(:terminate)
    else
      screen = Screen.where(url:params[:url]).first_or_initialize
      screen.update_attributes(params)
    end
  end

  def terminate
    if user_id
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
    Screen.where(state:[STATE_PAUSED,STATE_CASTING],updated_at:range).each(&:terminate)
  end

  def self.getSorted(limit)
    cleanup
    screens=Arel::Table.new :screens
    arrcasting=Screen.where(state:STATE_CASTING).order(screens[:pause_count],screens[:current_viewer].desc).limit(limit);
    if arrcasting.count<limit
      arrcasted=Screen.where(state:STATE_PAUSED).limit(limit-arrcasting.count)
    else
      arrcasted=[]
    end
    arrcasting+arrcasted
  end

  def as_json options={}
    {url:url,title:title,color:color,viewer:current_viewer,casting:casting?,vt100:vt100}
  end

  def to_json options={}
    as_json.to_json
  end
end
