require 'spec_helper'

describe UserController do
  context 'signin' do
    it 'should success' do
      get 'signin'
      response.should be_success
    end
  end
  context 'create account' do
    it 'should success if valid' do
      post 'create',signup:{name:'hogee',email:'aa@bb',password:'piyo',}
      response.should redirect_to user_index_path
      User.where(name:'hogee').first.should_not be_nil
    end
  end
  context 'signin' do
    name, email, password = 'hoge', 'aa@bb', 'piyo'
    before do
      User.create_account name:'hoge',email:'aa@bb',password:'piyo'
    end
    it 'can login with name' do
      post 'signin', name_or_email: name, password: password
      response.should redirect_to user_index_path
    end
    it 'can login with email' do
      post 'signin', name_or_email: email, password: password
      response.should redirect_to user_index_path
    end
    context 'after signin' do
      before do
        post 'signin', name_or_email: name, password: password
      end
      it 'should redirect signin to index' do
        get 'signin'
        response.should redirect_to user_index_path
      end
    end
  end
end

