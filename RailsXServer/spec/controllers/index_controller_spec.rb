require 'spec_helper'

describe IndexController do
  context 'index' do
    render_views
    before{get :index}
    it 'responds success' do
      response.should be_success
    end
    it '@screens' do
      assigns[:screens].class.should_not be_nil
    end
  end
  context 'static page' do
    render_views
    pages=[:team,:howto]
    pages.each do |page|
      it "get #{page}" do
        get page
        response.should be_success
      end
    end
  end
end

