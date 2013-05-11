require 'spec_helper'

describe OauthController do
  pending 'routing'
  context 'callback' do
    before do
      @user = User.new_account name:'tompng',email:'aa@bb',password:'pswd'
      @user.save
      @user.oauth_connect provider:'twitter',uid:'1',name:'name'
    end
    context 'nonuser' do
      before do
        request.env['omniauth.auth']={info:{},credentials:{}}
      end
      it 'donot popup' do
        OauthController.any_instance.should_receive :build_oauth_session
        post :callback, provider:''
        response.should redirect_to users_sign_in_path
      end
      it 'will popup' do
        OauthController.any_instance.should_receive :build_oauth_session
        post :callback, provider:'', popup:nil
        response.should be_success
      end
    end
    context 'user' do
      it 'callback and login' do
        OauthController.any_instance.should_receive :build_oauth_session
        OauthController.any_instance.should_receive :connect_and_build_user_session
        request.env['omniauth.auth']={provider:'twitter',uid:'1',info:{},credentials:{}}
        post :callback, provider:''
        response.should redirect_to users_index_path
      end
      it 'callback and login' do
        do_login @user
        OauthController.any_instance.should_receive :build_oauth_session
        OauthController.any_instance.should_receive :connect_and_build_user_session
        request.env['omniauth.auth']={provider:'facebook',uid:'1',info:{},credentials:{}}
        post :callback, provider:''
        response.should redirect_to users_index_path
      end
    end
  end

  it 'switch success' do
    OauthController.any_instance.should_receive(:switch_oauth_session).with('twitter')
    post :switch, provider:'twitter'
    response.should be_success
  end
  it 'disconnect fails if nonuser' do
    do_oauth provider:'twitter',uid:'1',name:'name'
    session[:oauth]['twitter'].should_not be_nil
    post :disconnect, provider:'twitter'
    response.should be_success
    response.body.should be_blank
  end
  it 'disconnect success' do
    user = User.new_account name:'tompng',email:'aa@bb',password:'pswd'
    user.save
    user.oauth_connect provider:'twitter',uid:'1',name:'name'
    do_login user
    session[:oauth]['twitter'].should_not be_nil
    expect{
      post :disconnect, provider:'twitter'
      session[:oauth]['twitter'].should be_nil
      response.should redirect_to users_index_path
    }.to change(Oauth,:count).by -1
  end
end

