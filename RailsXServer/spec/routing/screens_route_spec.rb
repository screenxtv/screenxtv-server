require 'spec_helper'

describe 'screens controller routing' do
  context 'api' do
    it 'status' do
      {get:'/screens/status/hoge'}.should route_to 'screens#status',url:'hoge'
      {get:'/screens/status/hoge/piyo'}.should route_to 'screens#status',url:'hoge',key:'piyo'
    end
  end

  context 'show' do
    it 'embed' do
      {get:'/embed/hoge'}.should route_to 'screens#show_embed',url:'hoge'
    end
    it 'show' do
      routing({get:'/screens/show/hoge'},{get:'/hoge'}).should route_to 'screens#show',url:'hoge'
    end
    it 'private' do
      routing({get:'/private/hoge'}).should route_to 'screens#show_private',url:'hoge'
    end
  end

  context 'chat' do
    it 'public' do
      pending#routing({get:'/chat/hoge'},{get:'/hoge'}).should route_to 'screens#chat_public',url:'hoge'
    end
    it 'private' do
      pending#routing({get:'/private/chat/hoge'}).should route_to 'screens#chat_private',url:'hoge'
    end
  end

  it 'post' do
    routing({get:'/screens/post/a/b'},{get:'/screens/post/a'}).should_not be_routable
    {post:'/screens/post/hoge/piyo'}.should route_to 'screens#post',room:'hoge',id:'piyo'
    {post:'/screens/post/hoge'}.should route_to 'screens#post',url:'hoge'
  end
end

