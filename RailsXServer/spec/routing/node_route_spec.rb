require 'spec_helper'

describe 'node action routing' do
  it 'notify' do
    routing(
      {post:'/screen_notify/hoge'},
      {post:'/screens/notify/hoge'}
    ).should route_to 'screens#notify',url:'hoge'
  end
  it 'auth' do
    {post:'/users/authenticate/hoge'}.should route_to 'users#authenticate',url:'hoge'
  end
  it 'auth old' do
    {post:'/screens/authenticate/hoge'}.should route_to 'screens#authenticate',url:'hoge'
  end
end

