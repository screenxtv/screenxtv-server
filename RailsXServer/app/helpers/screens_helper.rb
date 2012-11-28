module ScreensHelper
  def post(slug,message,social)
    if(social&&social.send?)then social.send message end
    Screen.where(slug:slug).post social&&social.name, message;
  end
end

