class Screen < ActiveRecord::Base
  attr_accessible :url,:total_viewer,:max_viewer,:total_time,:last_cast
    :current_time,:current_viewer,:current_max_viewer,:current_total_viewer,
    :pause_count,:title,:color,:vt100
  belongs_to :user
  STATE_CASTING=2
  STATE_PAUSED=1
  STATE_NONE=0
  def info
    {
      total_viewer:total_viewer||0,
      max_viewer:max_viewer||0,
      total_time:total_time||0
    }
  end
  def casting?
    state==STATE_CASTING
  end
  def self.notify(params)
    screen=Screen.where(url:params[:url]).first;
    if params[:status]=='terminate'
      screen.destroy if screen
      return false
    end
    params[:last_cast]=Time.now
    if params[:status]=='update'
      params[:state]=STATE_CASTING
    elsif params[:status]=='castend'
      params[:state]=STATE_PAUSED
    end

    if !screen
      screen=Screen.create(params)
      true
    else
      screen.update_attributes params.slice *screen.attribute_names.map(&:to_sym)
      false
    end
  end
  def terminate
    state=STATE_NONE
    title=color=vt100=nil
    current_time=current_viewer=current_max_viewer=current_total_viewer=pause_count=0
    if user
      save
    else
      destroy
    end
  end
  def self.cleanup
    range=0x10000.days.ago..10.minutes.ago
    Screen.where(state:[STATE_PAUSED,STATE_CASTING],updated_at:range).each{|screen|
      screen.terminate
    }
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
  def to_json
    ("{"+"\"url\":"+url.to_json+","+
    "\"title\":"+title.to_json+","+
    "\"color\":"+color.to_json+","+
    "\"viewer\":"+current_viewer.to_s+","+
    "\"casting\":"+(state==STATE_CASTING).to_s+","+
    "\"vt100\":"+vt100+"}").gsub("<","\\u003c").gsub(">","\\u003e");
  end
end
