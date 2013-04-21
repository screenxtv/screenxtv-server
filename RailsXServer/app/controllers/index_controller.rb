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
end
