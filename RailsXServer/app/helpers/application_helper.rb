module ApplicationHelper
  def safe_json obj
    obj.to_json.gsub("<","\\u003c").gsub(">","\\u003e").html_safe
  end
  def node_port
    ENV['NODE_PORT'].to_i
  end
  def title
    title="ScreenX TV"
    subtitle = @title || content_for(:title)
    if subtitle.present?
      "#{subtitle} - #{title}"
    else
      title
    end
  end

  def oauth_login_path provider
    "/auth/#{provider}"
  end

  def oauth_popup_path provider
    "/auth/#{provider}?popup"
  end
end
