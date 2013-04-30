require 'spec_helper'

describe UsersController do
  context 'sign_in' do
    it 'should success' do
      get 'sign_in'
      response.should be_success
    end
  end
  context 'sign_up' do
    it 'should success if valid' do
      post 'sign_up',sign_up:{name:'hogee',email:'aa@bb',password:'piyo'}
      response.should redirect_to users_index_path
      User.where(name:'hogee').first.should_not be_nil
    end
  end
  context 'sign_in' do
    name, email, password = 'hoge', 'aa@bb', 'piyo'
    before do
      User.new_account(name:name,email:email,password:password).save
    end
    it 'can login with name' do
      post 'sign_in', sign_in:{name_or_email:name, password:password}
      response.should redirect_to users_index_path
    end
    it 'can login with email' do
      post 'sign_in', sign_in:{name_or_email:email, password:password}
      response.should redirect_to users_index_path
    end
    context 'after sign_in' do
      before do
        post 'sign_in', sign_in:{name_or_email:name, password:password}
      end
      it 'should redirect sign_in to index' do
        get 'sign_in'
        response.should redirect_to users_index_path
      end
    end
  end
end

