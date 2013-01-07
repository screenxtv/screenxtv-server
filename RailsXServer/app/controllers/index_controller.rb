class IndexController < ApplicationController
  def index
    @footer=true
    @screens=Screen.getSorted(100)
  end

  def howto
    @footer=true
    @title='Install'
  end
  def team
    @footer=true
    @title='Team'
  end

  def embed
    @title=params[:url]
    @url=params[:url]
    @link=params[:link]
    render layout:false
  end

  def screen
    @title=params[:url]
    @url=params[:url]
    screen=Screen.where(url:@url).first
    @share=screen && screen.user ? true : false;
    @chats=screen ? screen.chats_for_js : []
  end
end
