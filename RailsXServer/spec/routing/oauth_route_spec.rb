require 'spec_helper'

describe 'oauth controller routing' do
  it 'callback' do
    routing({get:'/auth/twitter/callback'},{get:'/oauth/twitter/callback'}).should route_to 'oauth#callback',provider:'twitter'
  end
  it 'switch' do
    {get:'/oauth/switch'}.should_not be_routable
    {post:'/oauth/switch'}.should route_to 'oauth#switch'
  end
  it 'switch' do
    {get:'/oauth/disconnect'}.should_not be_routable
    {post:'/oauth/disconnect'}.should route_to 'oauth#disconnect'
  end
end

