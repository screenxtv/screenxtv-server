class ScreensController < ApplicationController
  before_filter :nodejs_filter, only:[:notify,:authenticate]
  protect_from_forgery :except=>[:notify,:authenticate]
  layout false

  NODE_PORT=ENV['NODE_PORT']

  def HTTPPost(host,port,path,hash)
    Net::HTTP.new(host,port).post(path,URI.encode_www_form(hash))
  end

  def index
    @screens=Screen.getSorted(100).select{|s|s.casting?}.map{|s|{url:s.url,title:s.title}}
    respond_to do |format|
      format.html{render nothing:true}
      format.json{render json:@screens}
    end
  end

  def show_embed
    @title=params[:url]
    @url=params[:url]
    @link=params[:link]
    render 'embed'
  end

  def show
    @title=params[:url]
    @url=params[:url]
    screen=Screen.where(url:@url).first
    @share=screen && screen.user ? true : false;
    @chats=screen ? screen.chats : []
    if params.include? :chat
      render 'chat'
    end
  end

  def show_private
    @title=params[:url]
    @url="private/#{params[:url]}"
    @share=false
    @chats=[]
    @private=true
    if params.include? :chat
      render action:'chat'
    else
      render 'show'
    end
  end


  def post
    name=current_user_name
    icon=current_user_icon
    max_length=100
    max_chats=256
    message=params[:message].strip[0,max_length]
    twitterclient=twitter if social_info && params[:twitter]
    if params[:url]
      url=params[:url]
      private_flag=false
    else
      url=params[:room]+'/'+params[:id]
      private_flag=true
    end
    Thread.new{
      return if message.size==0
      data={type:'chat',name:name,icon:icon,message:message}
      HTTPPost(NODE_IP,NODE_PORT,"/"+url,data)
      twitterclient.update message+" http://screenx.tv/"+url if twitterclient
    }
    if !private_flag
      screen=Screen.where(url:url).first
      if screen&&screen.user
        screen.chats.create(name:name,icon:icon,message:message)
        screen.chats.order('created_at DESC').offset(max_chats).destroy_all
      end
    end
    render nothing:true
  end

  def authenticate
    if params[:password]
      user=User.where(name:params[:user]).first
      if user && user.check_password(params[:password])
        render json:{auth_key:user.auth_key}
      else
        render json:{error:'wrong user or password'}
      end
      return
    end
    screen=Screen.where(url:params[:url]).first
    if screen
      chats=screen.chats_for_js
    end
    if screen.nil? || screen.user.nil?
      render json:{cast:true}
    elsif params[:auth_key]&&params[:user]
      if screen.user.name!=params[:user]
        render json:{cast:false,error:"wrong user"}
      elsif screen.user.auth_key!=params[:auth_key]
        render json:{cast:false,error:"wrong auth_key"}
      else
        render json:{cast:true,info:screen.info,chats:chats}
      end
    else
      render json:{cast:false,error:"url reserved"}
    end
  end

  def notify
    created=Screen.notify params
    if created && params[:title]!="Anonymous Sandbox"
      title=params[:title]
      title_max=40
      title=title[0,title_max-3]+"..." if title.length>title_max
      url="http://screenx.tv/#{params[:url]}"
      tweet="'#{title}' started broadcasting! Check this out #{url}"
      news_twitter.update tweet
    end
    render nothing:true
  end

  def status
    info = Screen.where(url:params[:url]).first
    if info
      out = {
        'title'=>info.title,
        'color'=>info.color,
        'viewer'=>info.current_viewer,
        'casting'=>info.casting?
      }
      out = out[params[:key]] if params[:key]
    end
    render json:out
  end
end
