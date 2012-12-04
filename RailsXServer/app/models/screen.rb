class Screen < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :url


  def self.notify(params)
  	screen=Screen.where(url:params[:url]).first;
    screen=Screen.create(url:params[:url]) if !screen
    case params[:status]
    when 'update'
      screen.title=params[:title]
      screen.color=params[:color]
      screen.vt100=params[:vt100]
      screen.casting=true
      screen.viewer=params[:viewer]
      screen.pausecount=params[:pause]
      screen.save
    when 'castend'
      screen.casting=false
      screen.viewer=screen.pausecount=0
      screen.save
    when 'terminate'
      screen.destroy
    end
  end
  def self.getSorted(limit)
    Screen.delete_all(["updated_at <= ?",1.minute.ago])
    screens=Arel::Table.new :screens
    arrcasting=Screen.where(casting:true).order(screens[:pausecount],screens[:viewer].desc).limit(limit);
    arrcasted=Screen.where(casting:false).limit(limit-arrcasting.count);
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
