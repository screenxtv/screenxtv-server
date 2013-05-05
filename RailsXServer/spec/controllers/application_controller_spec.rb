require 'spec_helper'

describe ApplicationController do
  controller do
    def index
      @result = self.send params[:method], *params[:args]
      render nothing:true
    end
  end
  def method_missing name, *args
    if /test_(?<method>[a-zA-Z0-9_]+)/ =~ name
      get :index, method: method, args: args
      assigns[:result]
    else
      super
    end
  end

  context '404' do
    controller do
      def index
        render_404
      end
    end
    it 'should render 404' do
      get :index
      response.status.should eq 404
    end
  end

  context 'when nonuser' do
    it 'should get anonymous social_info' do
      result = test_social_info
      result.should_not be_nil
      result[:main].should eq 'anonymous'
    end
    it 'should switch to anonymous' do
        
    end
  end


end

