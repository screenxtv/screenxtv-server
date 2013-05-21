class ScreensController < ApplicationController
  before_filter :nodejs_filter, only: [:notify, :authenticate]
  protect_from_forgery except: [:notify, :authenticate]
  layout false

  def post_to_node path, hash
    Net::HTTP.new(NODE_HOST, NODE_PORT).post(path, URI.encode_www_form(hash))
  end

  def index
    @screens=Screen.getSorted(100).select{|s|s.casting?}.map{|s|{url: s.url, title: s.title}}
    respond_to do |format|
      format.html{render nothing: true}
      format.json{render json: @screens}
    end
  end

  def show_embed
    @url = params[:url]
    render 'embed'
  end

  def show
    @url=params[:url]
    @screen=Screen.where(url: @url).first
    if @screen && @screen.user
      @share = true
      @owner = @screen.user
    end
    @title=@screen ? @screen.title || @url : @url
    @chats=@screen ? @screen.chats : []
    render 'chat' if params.include? :chat
  end

  def chat
    @url=params[:url]
    @screen=Screen.where(url: @url).first
    @title=@screen ? @screen.title : params[:url]
    @share = true if @screen && @screen.user
    @chats=screen ? screen.chats : []
    render 'chat'
  end

  def chat_private
    @title=params[:url]
    @url="private/#{params[:url]}"
    @chats=[]
    @private=true
    render 'chat'
  end

  def show_private
    @title=params[:url]
    @url="private/#{params[:url]}"
    @share=false
    @chats=[]
    @private=true
    render params.include?(:chat) ? 'chat' : 'show'
  end


  def post
    user = social_info[social_info[:main]]
    max_length = 100
    max_chats = 256
    message = params[:message].strip[0, max_length]
    render nothing: true and return if message.empty?
    if user_signed_in?
      user_url = url_for(controller: :users, action: :show, name: current_user.name)
    else
      user_url = Oauth.url_for user
    end
    data = {name: user[:display_name], icon: user[:icon], url: user_url, message: message}
    nodedata = data.merge type: 'chat', rand: params[:rand]

    if params[:url]
      url = params[:url]
      post_to_node "/#{params[:url]}", nodedata
      if social_info['twitter'] && params[:post_to_twitter].to_s == 'true'
        twitter_post_to_user "#{message} http://screenx.tv/#{url}"
      end
      screen = Screen.where(url: url).first
      if screen && screen.user_id
        screen.chats.create(data)
        screen.chats.order('created_at DESC').offset(max_chats).destroy_all
      end
    elsif params[:room] && params[:id]
      post_to_node "/#{params[:room]}/#{params[:id]}", nodedata
    end
    render nothing: true
  end

  def authenticate
    if params[:password]
      user=User.where(name: params[:user]).first
      if user && user.check_password(params[:password])
        render json: {auth_key: user.auth_key}
      else
        render json: {error: 'wrong user or password'}
      end
      return
    end
    Screen.cleanup
    screen=Screen.where(url: params[:url]).first
    if screen.nil? || screen.user.nil?
      render json: {cast: true}
    else
      if screen.user.name!=params[:user]
        render json: {cast: false, error: "reserved:#{screen.user.name}", user: screen.user.name}
      elsif screen.user.auth_key!=params[:auth_key]
        render json: {cast: false, error: "wrong auth_key"}
      else
        render json: {cast: true, info: screen.info, chats: screen.chats}
      end
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
    render nothing: true
  end

  def post_twitter_news params
    title=params[:title] || ''
    title_max=40
    title=title[0, title_max-3]+"..." if title.length>title_max
    url="http://screenx.tv/#{params[:url]}"
    tweet="'#{title}' started broadcasting! Check this out #{url}"
    twitter_post_to_news tweet
  end

  def status
    info = Screen.where(url: params[:url]).first
    if info
      out = {
        'title'=>info.title,
        'color'=>info.color,
        'viewer'=>info.current_viewer,
        'casting'=>info.casting?
      }
      out = out[params[:key]] if params[:key]
    end
    render json: out
  end

  def thumbnail
    screen = Screen.where(url: params[:url]).first
    if screen && screen.vt100
      data = TerminalThumbnail.create JSON.parse(screen.vt100), screen.color, screen.title
    else
      data = File.read("#{Rails.root}/app/assets/images/logo_large.png")
    end
    response.headers['Content-Type'] = 'image/png'
    render text: data
  end
end
