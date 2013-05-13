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
    context 'user' do
      before do
        @user.oauth_connect provider:'twitter',uid:'1',name:'name',display_name:'hoge'
        do_login @user
      end
      it 'twitter' do
        ApplicationController.any_instance.should_receive(:twitter_post_to_user) do |text|
          text.should include 'msg'
        end
        ScreensController.any_instance.should_receive(:post_to_node)
        post :post, url:'tompng',provider:'anonymous', message:'msg', post_to_twitter:true
      end
      it 'notwitter' do
        ScreensController.any_instance.should_receive(:post_to_node)
        ApplicationController.any_instance.should_not_receive :twitter_post_to_user
        post :post, url:'tompng',provider:'anonymous', message:'msg', post_to_twitter:'false'
      end
    end
    it 'post anonymous' do
      ApplicationController.any_instance.should_not_receive :twitter_post_to_user
      ScreensController.any_instance.should_receive(:post_to_node)
      expect{
        post :post, url:'tompng',provider:'anonymous', message:'msg'
        response.should be_success
      }.to change(Chat,:count).by 1
    end
    it 'post private' do
      ApplicationController.any_instance.should_not_receive :twitter_post_to_user
      ScreensController.any_instance.should_receive(:post_to_node)
      do_login @user
      expect{
        post :post, room:'private',id:'abc',provider:'anonymous', message:'msg', post_to_twitter:true
        response.should be_success
      }.not_to change(Chat,:count)
    end
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
    end
    context 'notify' do
      [['start',Screen::STATE_CASTING],['update',Screen::STATE_CASTING],['stop',Screen::STATE_PAUSED]].each do |status,state|
        context status do
          before{
            if status == 'start'
              ApplicationController.any_instance.should_receive :twitter_post_to_news do |text|
                text.should include 'aaa'
              end
            else
              ApplicationController.any_instance.should_not_receive :twitter_post_to_news
            end
            post :notify, url:'aaa', status:status, current_viewer:1
          }
          it('response'){response.should be_success}
          subject{Screen.where(url:'aaa').first}
          its(:state){should eq state}
          its(:current_viewer){should eq 1}
        end
      end
      context 'destroy' do
        context 'nonuser' do
          before{
            ApplicationController.any_instance.should_receive(:twitter_post_to_news).once
            post :notify, url:'aaa', status:'start', current_viewer:1
            post :notify, url:'aaa', status:'destroy', current_viewer:1
          }
          it('response'){response.should be_success}
          it('should delete'){Screen.where(url:'aaa').count.should be_zero}
        end
        context 'user' do
          before{
            ApplicationController.any_instance.should_receive(:twitter_post_to_news).once
            post :notify, url:'tompng', status:'start', current_viewer:1
            post :notify, url:'tompng', status:'destroy', current_viewer:1
          }
          it('response'){response.should be_success}
          subject{Screen.where(url:'tompng').first}
          its(:state){should eq Screen::STATE_NONE}
        end
      end
    end
  end
end

