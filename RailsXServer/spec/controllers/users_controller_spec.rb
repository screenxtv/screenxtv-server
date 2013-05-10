require 'spec_helper'

describe UsersController do
  name, email, password = 'hoge', 'aa@bb', 'piyo'
  before do
    @user = User.new_account(name:name,email:email,password:password)
    @user.save
  end
  context 'sign_up' do
    context 'get' do
      render_views
      it 'should success' do
        get :sign_up
        response.should be_success
      end
    end
    it 'should not create if get' do
      get :sign_up,sign_up:{name:'hogee',email:'aaa@bbb',password:'piyo'}
      response.should be_success
      User.where(name:'hogee').first.should be_nil
    end
    it 'should success if valid' do
      post :sign_up,sign_up:{name:'hogee',email:'aaa@bbb',password:'piyo'}
      response.should redirect_to users_index_path
      User.where(name:'hogee').first.should_not be_nil
    end
    it 'should render sign_in if invalid' do
      post :sign_up,sign_up:{name:name,email:email,password:password}
      response.should be_success
    end
  end
  context 'sign_in' do
    context 'get' do
      render_views
      it 'should success' do
        get :sign_in
        response.should be_success
      end
    end
    it 'should not login if get' do
      get :sign_in, sign_in:{name_or_email:name, password:password}
      response.should be_success
    end
    it 'can login with name' do
      post :sign_in, sign_in:{name_or_email:name, password:password}
      response.should redirect_to users_index_path
    end
    it 'can login with email' do
      post :sign_in, sign_in:{name_or_email:email, password:password}
      response.should redirect_to users_index_path
    end
    context 'after sign_in' do
      before do
        post :sign_in, sign_in:{name_or_email:name, password:password}
      end
      it 'should redirect sign_in to index' do
        get :sign_in
        response.should redirect_to users_index_path
      end
    end
  end
  context 'show user' do
    it 'should 404 when not foun' do
     get :show,name:'noname'
     response.status.should eq 404
    end
    context 'get' do
      render_views
      before{get :show,name:name}
      it 'should success' do
        response.should be_success
      end
      it 'should set correct @user' do
        assigns[:user].id.should eq User.where(name:name).first.id
      end
    end
  end


  context 'node action' do
    context 'authenticate' do
      context 'password' do
        context 'wrong user' do
          before{post :authenticate, user:'hogee',password:'hoge'}
          subject{response}
          it{should be_success}
          its(:body){should include 'error'}
        end
        context 'wrong pswd' do
          before{post :authenticate, user:'hoge',password:'fuga'}
          subject{response}
          it{should be_success}
          its(:body){should include 'error'}
        end
        context 'correct' do
          before{post :authenticate, user:'hoge',password:'piyo'}
          subject{response}
          it{should be_success}
          its(:body){should eq({auth_key:@user.auth_key}.to_json)}
        end
      end
    end
  end

  context 'after_sign_in' do
    before do
      post :sign_in, sign_in:{name_or_email:name, password:password}
    end
    it 'can sign out' do
      post :sign_out
      get :index
      response.should be_redirect
    end
    context 'index' do
      render_views
      it 'get should success' do
        get :index
        response.should be_success
      end
    end

    context 'edit' do
      pending
    end
  end
end

