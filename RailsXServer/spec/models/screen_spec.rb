require 'spec_helper'

describe Screen do
  before do
    @user = User.new_account(name:'name',email:'e@main',password:'pswd')
    @user.save
    @userscreen = @user.screens.first
    @screen = Screen.create(url:'fooo')
  end

  context 'action from node' do
    context 'method' do
      it 'info' do
        info = @screen.info
        keys = [:total_viewer,:max_viewer,:total_time,:cast_count]
        keys.each do |key|
          info[key].class.should eq Fixnum
        end
        info[:total_viewer]
      end
      it 'terminate' do
        expect{@userscreen.terminate}.not_to change(Screen,:count)
        expect{@screen.terminate}.to change(Screen,:count).by -1
      end
      it 'casting? should work' do
        Screen.new(state:Screen::STATE_CASTING).casting?.should be_true
        Screen.new(state:Screen::STATE_PAUSED).casting?.should be_false
      end
    end
    context 'notify' do
      def param state,screen=nil
        {url:(screen ? screen.url : 'hoge'),total_viewer:1,state:state}
      end
      def screen
        Screen.where(url:'hoge').first
      end
      [['casting',Screen::STATE_CASTING],['paused',Screen::STATE_PAUSED]].each do |key, value|
        context key do
          it 'should create' do
            Screen.notify param(value)
            screen.should_not be_nil
            screen.total_viewer.should eq 1
            screen.state.should eq value
          end
          it 'should update' do
            Screen.notify param(value,@screen)
            @screen.reload
            @screen.total_viewer.should eq 1
            @screen.state.should eq value
          end
        end
      end
      context 'none' do
        it 'should not create' do
          expect{Screen.notify param(Screen::STATE_NONE)}.not_to change(Screen,:count)
        end
        it 'should terminate' do
          expect{Screen.notify param(Screen::STATE_NONE,@screen)}.to change(Screen,:count).by -1
        end
      end
    end
    it 'no error on call getSorted' do
      Screen.getSorted(100).should_not be_nil
    end
    context 'cleanup' do
      def set url,state,minutes,has_user=false
        Screen.record_timestamps=false
        screen=Screen.new(url:url,state:state)
        screen.current_viewer=1
        screen.created_at=screen.updated_at=minutes.minutes.ago
        screen.user_id = has_user ? 1 : nil
        screen.save
        Screen.record_timestamps=true
        screen
      end
      before do
        @screen_update=[]
        @screen_remain=[]
        @screen_delete=[]
        url='hoge'
        @screen_remain << set(url.next!,Screen::STATE_NONE,9,true)
        @screen_remain << set(url.next!,Screen::STATE_NONE,11,true)
        @screen_remain << set(url.next!,Screen::STATE_CASTING,9,true)
        @screen_update << set(url.next!,Screen::STATE_CASTING,11,true)
        @screen_remain << set(url.next!,Screen::STATE_PAUSED,9,true)
        @screen_update << set(url.next!,Screen::STATE_PAUSED,11,true)
        @screen_remain << set(url.next!,Screen::STATE_CASTING,9,false)
        @screen_delete << set(url.next!,Screen::STATE_CASTING,11,false)
        @screen_remain << set(url.next!,Screen::STATE_PAUSED,9,false)
        @screen_delete << set(url.next!,Screen::STATE_PAUSED,11,false)
        Screen.cleanup
      end
      it 'do nothing if state_none, time<10' do
        @screen_remain.each{|s|
          s.reload
          s.current_viewer.should eq 1
        }
      end
      it 'change if user, time>10' do
        @screen_update.each{|s|
          s.reload
          s.current_viewer.should eq 0
        }
      end
      it 'delete if nonuser, time>10' do
        @screen_delete.each{|s|
          Screen.where(url:s.url).first.should be_nil
        }
      end
    end
  end
end
