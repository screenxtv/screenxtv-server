class ScreensController < ApplicationController
  before_filter :localfilter, only:[:notify,:authenticate]
  protect_from_forgery :except=>[:notify,:authenticate]
  NODE_IP="127.0.0.1"
  NODE_PORT=ENV['NODE_PORT']
  def localfilter
    render nothing:true if request.remote_ip!=NODE_IP
  end

  def HTTPPost(host,port,path,hash)
    query=hash.map{|x|x.map{|y|URI.encode(y.to_s).gsub("+","%2B")}.join("=")}.join("&")
    Net::HTTP.new(host,port).post(path,query)

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

  def authenticate
    user=User.where(name:params[:url]).first
    if params[:password]
      if !user
        render json:{cast:false,error:'wrong user'}
      elsif user.check_password params[:password]
        render json:{cast:true,auth_key:user.auth_key}
      else
        render json:{cast:false,error:'wrong password'}
      end
    end
    if !user
      render json:{cast:true}
      return
    end
    if params[:auth_key]
      if user.auth_key==params[:auth_key]
        render json:{cast:true}
      else
        render json:{cast:false,error:"wrong auth_key"}
      end
    else
      render json:{cast:false,error:"already in use"}
    end
  end

  def notify
    created=Screen.notify params
    if created && params[:title]!="Anonymous Sandbox"
      Thread.new{
        title=params[:title]
        title_max=40
        title=title[0,title_max-3]+"..." if title.length>title_max
        url="http://example.com/#{params[:url]}"
        tweet="'#{title}' started broadcasting! Check this out #{url}"
        print "NEWS_TWIT #{tweet}"#news_twitter.update tweet
      }
    end
    render nothing:true
  end

  def status
    info=Screen.where(url:params[:url]).first
    out=nil
    case params[:key]
      when 'title'
      out=info ? info.title : nil
      when 'color'
      out=info ? info.color : nil
      when 'viewer'
      out=info ? info.viewer : 0
      when 'casting'
      out=info ? info.casting : false
      when nil
      out={title:info.title,color:info.color,viewer:info.viewer,casting:info.casting} if info
    end
    render json:out
  end
end
