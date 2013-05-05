class IndexController < ApplicationController
  def index
    @screens=Screen.getSorted(100)
  end

  def howto
  end

  def team
  end
end
