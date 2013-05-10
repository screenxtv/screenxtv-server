require 'spec_helper'

describe ScreensController do
  before do
    @user=User.new_account name:'tompng',email:'e@mail',password:'pswd'
    @user.save
  end
  context 'views' do
    render_views
    it 'should respond to embed' do
      get :show_embed,url:'foo'
      assigns.should include(title:'foo',url:'foo')
      response.should be_success
      response.should render_template 'embed'
    end
    context 'public' do
      context 'when screen exists' do
        before{get :show,url:'tompng'}
        it 'assings' do
          assigns.should include(title:'tompng',url:'tompng',chats:[])
        end
        subject{response}
        it{should be_success}
        it{should render_template 'show'}
      end
      context 'when screen doesnot exist' do
        before{get :show,url:'tompng'}
        it 'assings' do
          assigns.should include(title:'tompng',url:'tompng',chats:[])
        end
        subject{response}
        it{should be_success}
        it{should render_template 'show'}
      end
    end
    context 'private' do
      context 'get' do
        before{get :show_private,url:'foo'}
        it 'assings' do
          assigns.should include(title:'foo',url:'private/foo',private:true,chats:[])
        end
        context 'response' do
          subject{response}
          it{should be_success}
          it{should render_template 'show'}
        end
      end
      context 'chat' do
        before{get :show_private,url:'foo',chat:''}
        subject{response}
        it{should be_success}
        it{should render_template 'chat'}
      end
    end
  end
  context 'status api' do
    it 'success get url' do
      get :status, url:'hogehoge'
      response.should be_success
    end
    it 'success get url title' do
      get :status, url:'hogehoge', key:'title'
      response.should be_success
      response.body.should eq 'null'
    end
    it 'success get existing url' do
      data={title:'hoge',color:'red',viewer:0,casting:true}
      params={title:data[:title],color:data[:color],current_viewer:data[:viewer],state:Screen::STATE_CASTING}
      @user.screens.first.update_attributes(params)
      get :status, url:'tompng'
      response.should be_success
      response.body.should eq data.to_json
      get :status, url:'tompng', key:'title'
      response.should be_success
      response.body.should eq data[:title]
    end
  end
  context 'post' do
    it 'socialstream post'
  end
  context 'node action' do
    context 'authenticate' do
      context 'password(old ver)' do
        context 'wrong user' do
          before{post :authenticate, url:'_', user:'hoge',password:'pswd'}
          subject{response}
          it{should be_success}
          its(:body){should include 'error'}
        end
        context 'wrong pswd' do
          before{post :authenticate, url:'_', user:'tompng',password:'hoge'}
          subject{response}
          it{should be_success}
          its(:body){should include 'error'}
        end
        context 'correct' do
          before{post :authenticate, url:'_', user:'tompng',password:'pswd'}
          subject{response}
          it{should be_success}
          its(:body){should eq({auth_key:@user.auth_key}.to_json)}
        end
      end
      it 'auth from nodejs'
    end
    context 'notify' do
      it 'notify from rails'
    end
  end
end

