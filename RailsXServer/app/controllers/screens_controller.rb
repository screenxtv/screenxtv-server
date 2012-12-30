class ScreensController < ApplicationController
  before_filter :localfilter, only:[:notify,:authenticate]
  protect_from_forgery :except=>[:notify,:authenticate]
  NODE_IP="127.0.0.1"
  NODE_PORT=ENV['NODE_PORT']
  def localfilter
    render nothing:true if request.remote_ip!=NODE_IP
  end

  def HTTPPost(host,port,path,hash)
    Net::HTTP.new(host,port).post(path,URI.encode_www_form(hash))
  end

  def post
    Thread.new{
      max_length=100
      msg=params[:message].strip[0,max_length]
      return if msg.size==0
      data={type:'chat',name:current_user_name,icon:current_user_icon,message:msg}
      HTTPPost(NODE_IP,NODE_PORT,"/"+params[:url],data)
      if(user_signed_in? && params[:twitter]=='true')
        twitter.update msg+" http://screenx.tv/"+params[:url]
      end
    }
    render nothing:true
  end

  def authenticate
    if params[:password]
      user=User.where(name:params[:user]).first
      p user
      if user && user.check_password(params[:password])
        render json:{auth_key:user.auth_key}
      else
        render json:{error:'wrong user or password'}
      end
      return
    end
    screen=Screen.where(url:params[:url]).first
    if screen.nil? || screen.user.nil?
      render json:{cast:true}
    elsif params[:auth_key]&&params[:user]
      if screen.user.name!=params[:user]
        render json:{cast:false,error:"wrong user"}
      elsif screen.user.auth_key!=params[:auth_key]
        render json:{cast:false,error:"wrong auth_key"}
      else
        render json:{cast:true,info:screen.info}
      end
    else
      render json:{cast:false,error:"url reserved"}
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
