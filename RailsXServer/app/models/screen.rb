class Screen < ActiveRecord::Base
  attr_accessible :url
  belongs_to :user
  STATE_CASTING=2
  STATE_PAUSED=1
  STATE_NONE=0
  def info
    {
      total_viewer:total_viewer||0,
      max_viewer:total_viewer||0,
      total_time:total_viewer||0
    }
  end
  def self.notify(params)
    screen=Screen.where(url:params[:url]).first;
    if params[:status]=='terminate'
      screen.destroy if screen
      return false
    end
    if !screen
      screen=Screen.create(url:params[:url])
      createdflag=true
    else
      createdflag=false
    end

    screen.total_viewer=params[:total_viewer]
    screen.max_viewer=params[:max_viewer]
    screen.total_time=params[:total_time]

    screen.current_time=params[:current_time]
    screen.current_viewer=params[:current_viewer]
    screen.current_max_viewer=params[:current_max_viewer]
    screen.current_total_viewer=params[:current_total_viewer]
    screen.pause_count=params[:pause_count]
    screen.last_cast=Time.now
    screen.title=params[:title]
    screen.color=params[:color]
    screen.vt100=params[:vt100]
    screen.last_cast=Time.now
    if params[:status]=='update'
      screen.state=STATE_CASTING 
    elsif params[:status]=='castend'
      screen.state=STATE_PAUSED
      createflag=false
    end
    screen.save
    createdflag
  end
  def terminate
    state=STATE_NONE
    title=color=vt100=nil
    if user
      save
    else
      destroy
    end
  end
  def self.getSorted(limit)
    terminate_range=0x10000.days.ago..10.minutes.ago
    Screen.where(state:STATE_PAUSED,updated_at:terminate_range).each{|screen|
      screen.terminate
    }

    screens=Arel::Table.new :screens
    arrcasting=Screen.where(state:STATE_CASTING).order(screens[:pause_count],screens[:current_viewer].desc).limit(limit);
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
    "\"viewer\":"+viewer.to_s+","+
    "\"casting\":"+casting.to_s+","+
    "\"vt100\":"+vt100+"}").gsub("<","\\u003c").gsub(">","\\u003e");
  end
end
