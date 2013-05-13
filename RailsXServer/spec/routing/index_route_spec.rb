require 'spec_helper'

describe 'index controller routing' do
  it 'routes to index#index' do
    {get:'/'}.should route_to 'index#index'
  end
  context 'documents' do
    it 'team' do
      {get:'/doc/howto'}.should route_to 'index#howto'
    end
    it 'howto' do
      {get:'/doc/howto'}.should route_to 'index#howto'
    end
  end
end

