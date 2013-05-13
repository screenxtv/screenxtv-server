require 'spec_helper'

describe 'users controller routing' do
  context 'session' do
    it 'sign_in' do
      routing({get:'/users/sign_in'},{post:'/users/sign_in'}).should route_to 'users#sign_in'
    end
    it 'sign_up' do
      routing({get:'/users/sign_up'},{post:'/users/sign_up'}).should route_to 'users#sign_up'
    end
    it 'sign_out' do
      routing({get:'/users/sign_out'},{post:'/users/sign_out'}).should_not be_routable
      {delete:'/users/sign_out'}.should route_to 'users#sign_out'
    end
  end
  context 'page' do
    it 'show' do
      {get:'/users/show/hoge'}.should route_to 'users#show',name:'hoge'
    end
    it 'index' do
      {get:'/users/index'}.should route_to 'users#index'
    end
    it 'edit' do
      {get:'/users/edit'}.should route_to 'users#edit'
    end
    it 'update' do
      {get:'/users/update'}.should_not be_routable
      {post:'/users/update'}.should route_to 'users#update'
    end
    it 'screen update' do
      routing({get:'/users/create_screen'},{get:'/users/destroy_screen'},{get:'/users/change_screen'}).should_not be_routable
    end
  end
end

