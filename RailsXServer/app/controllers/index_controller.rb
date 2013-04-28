class IndexController < ApplicationController
  def index
    @screens=Screen.getSorted(100)
  end

  def howto
    @title='Install'
  end
  def team
    @title='Team'
  end
end
