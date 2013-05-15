require 'spec_helper'

describe ApplicationController do

  before do
    @user_with_twitter = User.create(name:'tompng2',email:'tompng2@tompng2',password:'tompng')
    @user_with_twitter.oauth_connect provider:'twitter',uid:'hoge',name:'pen'
    @user_with_facebook = User.create(name:'tompng3',email:'tompng3@tompng2',password:'tompng')
    @user_with_facebook.oauth_connect provider:'facebook',uid:'hoge',name:'pen'
  end
  controller do
    def index
      if params[:user_id]
        @result = self.send params[:method], User.find(params[:user_id])
      else
        @result = self.send params[:method], *params[:args]
      end
      render nothing:true
    end
  end
  def method_missing name, *args
    if /call_(?<method>[a-zA-Z0-9_!?]+)/ =~ name
      if method == 'build_user_session' || method == 'connect_and_build_user_session'
        get :index, method: method, user_id: args[0].id
      else
        get :index, method: method, args: args
      end
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

  context 'signed_in! redirect' do
    controller do
      def index
        user_signed_in!
      end
    end
    it 'should redirect' do
      get :index
      response.should be_redirect
    end
  end

  context 'when nonuser' do
    context 'current_user' do
      it 'should be nil' do
        call_current_user.should be_nil
      end
      it 'sign_in? shoule be false' do
        call_user_signed_in?.should be_false
      end
    end
    context 'no oauth' do
      it 'should get anonymous social_info' do
        call_social_info[:main].should eq 'anonymous'
      end
      it 'should success switching to anonymous' do
        call_switch_oauth_session 'anonymous'
        call_social_info[:main].should eq 'anonymous'
      end
      it 'should do nothing switching to oauth' do
        call_switch_oauth_session 'twitter'
        call_social_info[:main].should eq 'anonymous'
      end
    end
    context 'connect facebook' do
      before do
        call_build_oauth_session provider:'facebook',uid:'orz',name:'hoge'
      end
      context 'social_info' do
        it 'should return facebook' do
          info = call_social_info
          info[:main].should eq 'facebook'
          info['facebook'].should_not be_nil
        end
      end
      context 'connect twitter' do
        before do
          call_build_oauth_session provider:'twitter',uid:'orz',name:'hoge'
        end
        it 'should set main twitter' do
          info = call_social_info
          info[:main].should eq 'twitter'
          info['twitter'].should_not be_nil
          info['facebook'].should_not be_nil
        end
        it 'should success switching to facebook' do
          call_switch_oauth_session 'facebook'
          call_social_info[:main].should eq 'facebook'
        end
      end
    end
  end
  context 'when signin' do
    before do
      call_build_user_session @user_with_twitter
    end
    context 'current_user' do
      it 'should not be nil' do
        call_current_user.should_not be_nil
      end
      it 'sign_in? shoule be true' do
        call_user_signed_in?.should be_true
      end
      it 'should not redirect when signed_in!' do
        call_user_signed_in!
        response.should be_success
      end
    end
    it 'cannot switch except user' do
      call_switch_oauth_session 'twitter'
      call_social_info[:main].should eq :user
    end
    it 'can connect to facebook' do
      call_build_oauth_session provider:'facebook',uid:'orz',name:'hoge'
      call_connect_and_build_user_session @user_with_twitter
      @user_with_twitter.oauths.count.should eq 2
      info = call_social_info
      info['facebook'].should_not be_nil
      info['twitter'].should_not be_nil
      info[:main].should eq :user
    end
    it 'can update twitter' do
      call_build_oauth_session provider:'twitter',uid:'orz',name:'hoge'
      call_connect_and_build_user_session @user_with_twitter
      @user_with_twitter.oauths.where(uid:'orz').count.should eq 1
      info = call_social_info
      info['twitter'].should_not be_nil
      info[:main].should eq :user
    end
    it 'can destroy all session' do
      call_destroy_user_session
      call_current_user.should be_nil
      info = call_social_info
      info['twitter'].should be_nil
      info[:main].should eq 'anonymous'
    end
  end
end

