require 'spec_helper'

describe User do
  context 'digest methods' do
    it 'should be sha2' do
      User.digest('a').should eq 'ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb'
      User.digest('b').should eq '3e23e8160039594a33894f6564e1b1348bbd7a0088d42c4acb73eeaed59c009d'
    end
  end

  context 'when create' do
    ng={name:['','hog','aaaa&',nil],
        email:['','aaaa@','@bb',nil],
        password:['','aaa',nil]}
    ok={name:'aaaa',email:'aaa@aaa',password:'aaaa'}
    user = nil
    before do
      user = User.create_account(name:'hoge',email:'foo@bar',password:'piyo')
    end
    it 'should validate' do
      keys=[:name,:email,:password]
      keys.length.times.each do |i|
        ngkey=keys[i]
        ng[ngkey].each do |ngval|
          data={}.tap{|h|keys.each{|k,v|h[k]=v}}
          data[ngkey]=ngval
          User.create_account(data).should be_nil
        end
      end
    end
    it 'should save valid data' do
      User.create_account(ok).should_not be_nil
    end
    it 'should save valid data only once' do
      User.create_account(name:'hoge',email:ok[:email],password:ok[:password]).should be_nil
      User.create_account(name:ok[:name],email:'foo@bar',password:ok[:password]).should be_nil
    end
    it 'should be able to check password' do
      user.check_password('PIYO').should be_false
      user.check_password('piyo').should be_true
    end
    it 'should authenticate' do
      User.authenticate('hoge','piyo').id.should eq user.id
      User.authenticate('foo@bar','piyo').id.should eq user.id
      User.authenticate('bar@foo','piyo').should be_nil
    end
    context 'user_screen' do
      it 'should be able to create one\'s screen' do
        user.screens.create(url:'aaa').should_not be_nil
        user.screens.create(url:'bbb').should_not be_nil
        expect{user.screens.create(url:'aaa')}.to raise_error
      end
      context 'when screen exists' do
        it 'should fail creating account' do
          user.screens.create(url:'aaa').should be_true
          User.create_account(name:'aaa',email:ok[:email],password:ok[:password]).should be_nil
          User.where(name:'aaa').should be_empty
        end
      end
    end
  end
end
