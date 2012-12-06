module ApplicationHelper
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
