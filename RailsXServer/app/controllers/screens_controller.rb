class ScreensController < ApplicationController
  before_filter :nodejs_filter, only:[:notify,:authenticate]
  protect_from_forgery :except=>[:notify,:authenticate]
  layout false
  NODE_HOST = 'localhost'
  NODE_PORT = ENV['NODE_PORT']

  def post_to_node(path,hash)
    Net::HTTP.new(NODE_HOST, NODE_PORT).post(path,URI.encode_www_form(hash))
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
    info = social_info
    user = info[info[:main]]
    max_length = 100
    max_chats = 256
    message = params[:message].strip[0,max_length]
    render nothing:true and return if message.empty?
    if user_signed_in?
      user_url = url_for(controller: :users, action: :show, name: current_user.name)
    else
      user_url = Oauth.url_for user
    end
    data = {name:user[:display_name],icon:user[:icon],url:user_url,message:message}
    nodedata = data.merge type:'chat',rand:params[:rand]

    if params[:url]
      url=params[:url]
      post_to_node "/#{params[:url]}", nodedata
      if info['twitter'] && params[:post_to_twitter].to_s == 'true'
        twitter_post_to_user "#{message} http://screenx.tv/#{url}"
      end
      screen=Screen.where(url:url).first
      if screen && screen.user_id
        screen.chats.create(data)
        screen.chats.order('created_at DESC').offset(max_chats).destroy_all
      end
    elsif params[:room] && params[:id]
      post_to_node "/#{params[:room]}/#{params[:id]}", nodedata
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
    status = params[:status]
    params[:state] = {
      'start'=>Screen::STATE_CASTING,
      'update'=>Screen::STATE_CASTING,
      'stop'=>Screen::STATE_PAUSED,
      'destroy'=>Screen::STATE_NONE,
    }[status]
    Screen.notify params.slice *Screen.accessible_attributes
    post_twitter_news params if status == 'start' && params[:title] != "Anonymous Sandbox"
    render nothing:true
  end

  def post_twitter_news params
    title=params[:title] || ''
    title_max=40
    title=title[0,title_max-3]+"..." if title.length>title_max
    url="http://screenx.tv/#{params[:url]}"
    tweet="'#{title}' started broadcasting! Check this out #{url}"
    twitter_post_to_news tweet
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
