class IndexController < ApplicationController
  def index
    @screens=Screen.getSorted(100)
  end

  def howto
    @title='Install'
  end

  def embed
    @title=params[:url]
    @url=params[:url]
    @link=params[:link]
    render layout:false
  end

  def screen
    @url=params[:url]
    screen=Screen.where(url:@url).first
    @share=screen && screen.user ? true : false;
    @chats=screen ? screen.chats_for_js : []
  end
end
