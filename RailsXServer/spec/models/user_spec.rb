require 'spec_helper'

describe User do
  context 'digest methods' do
    it 'should be sha2' do
      User.digest('a').should eq 'ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb'
      User.digest('b').should eq '3e23e8160039594a33894f6564e1b1348bbd7a0088d42c4acb73eeaed59c009d'
    end
  end
  context 'when create' do
    before do
      @user = User.new_account(name:'hoge',email:'foo@bar',password:'piyo')
      @user2 = User.new_account(name:'HOGE',email:'FOO@BAR',password:'PIYO')
      @user.save
      @user2.save
    end

    it 'should create user' do
      expect {User.new_account(name:'hoge2',email:'foo2@bar',password:'piyo').save}.to change(User, :count).by(1)
    end

    it 'should validate presence of password' do
      expect{User.new_account(name:'hoge2',email:'foo2@bar').save}.not_to change(User, :count)
    end

    it 'should validate uniqueness of name' do
      expect{User.new_account(name:'hoge',email:'foo2@bar',password:'piyo').save}.not_to change(User, :count)
    end

    it 'should validate uniqueness of email' do
      expect{User.new_account(name:'hoge2',email:'foo@bar',password:'piyo').save}.not_to change(User, :count)
    end

    it 'should be able to check password' do
      @user.check_password('PIYO').should be_false
      @user.check_password('piyo').should be_true
    end

    it 'should find_user' do
      User.find_by_password('hoge','piyo').id.should eq @user.id
      User.find_by_password('foo@bar','piyo').id.should eq @user.id
      User.find_by_password('bar@foo','piyo').should be_nil
    end

    context 'user_screen' do
      it 'should be able to create one\'s screen' do
        expect{@user.screens.create(url:'aaaa')}.to change(Screen, :count).by(1)
        expect{@user.screens.create(url:'aaaa')}.not_to change(Screen, :count)
      end
      context 'when screen exists' do
        it 'should fail creating account' do
          @user.screens.create(url:'aaaa').should be_true
          expect{User.new_account(name:'aaaa',email:'foo2@bar',password:'piyo').save}.not_to change{[User.count,Screen.count]}
        end
      end
    end

    context 'oauth' do
      before do
        @user.oauth_connect provider:'hoge',uid:'1',name:'name'
      end
      it 'should connect to oauth' do
        expect{@user2.oauth_connect provider:'hoge',uid:'1',name:'name'}.to raise_error
        @user2.oauths.where(provider:'hoge').first.should be_nil
        expect{@user2.oauth_connect provider:'hoge',uid:'2',name:'name'}.to change(Oauth, :count).by(1)
        expect{@user.oauth_connect provider:'hoge',uid:'3',name:'new_name'}.not_to change(Oauth, :count)
        @user.oauths.where(provider:'hoge').first.name.should eq 'new_name'
      end
      it 'should disconnect oauth' do
        @user2.oauth_connect provider:'hoge',uid:'2',name:'name'
        expect{@user.oauth_disconnect 'hoge'}.to change(Oauth, :count).by(-1)
      end
      it 'should use oauth icon and displayname onlyif nil' do
        name=@user.name
        @user.oauth_connect provider:'piyo',uid:'2',name:'name2',icon:'icon',display_name:'NAME'
        @user.name.should eq name
        @user.oauth_connect provider:'foo',uid:'2',name:'bar',icon:'icon2',display_name:'NAME2'
        @user.display_name.should eq 'NAME'
        @user.icon.should eq 'icon'
      end

    end
  end
end
