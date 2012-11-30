class ScreensController < ApplicationController
  before_filter :localfilter, only:[:notify]
  protect_from_forgery :except=>[:notify]
  NODE_IP="127.0.0.1"
  NODE_PORT=ENV['NODE_PORT']
  def localfilter
    render nothing:true if request.remote_ip!=NODE_IP
  end

  def HTTPPost(host,port,path,hash)
    query=hash.map{|x|x.map{|y|URI.encode(y.to_s)}.join("=")}.join("&")
    Net::HTTP.new(host,port).post(path,query).body
  end

  def post
    Thread.new{
      HTTPPost(NODE_IP,NODE_PORT,"/"+params[:url],{type:'chat',name:session[:user].to_json,message:params[:message]})
      if(authorized? && params[:twitter]=='true')
        twitter.update params[:message]+" http://screenx.tv/"+params[:url]
      end
    }
    render nothing:true
  end

  def notify
    Screen.notify params
    render nothing:true
  end
end
