module ApplicationHelper
  def safe_json obj
    obj.to_json.gsub("<","\\u003c").gsub(">","\\u003e").html_safe
  end
  def node_port
    ENV['NODE_PORT']
  end
  def title
    title="ScreenX TV"
    if @title
      "#{@title} - #{title}"
    else
      title
    end
  end
end
