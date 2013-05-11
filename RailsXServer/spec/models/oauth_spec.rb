require 'spec_helper'

describe Oauth do
  context 'social urls' do
    it 'should return twitter url' do
      Oauth.new(provider:'twitter',name:'tompng').url.should eq("http://twitter.com/tompng")
      Oauth.url_for(Oauth.new provider:'twitter',name:'tompng').should eq("http://twitter.com/tompng")
    end
    it 'should return facebook url' do
      Oauth.new(provider:'facebook',name:'hoge').url.should eq("http://www.facebook.com/hoge")
      Oauth.url_for(Oauth.new provider:'facebook',name:'hoge').should eq("http://www.facebook.com/hoge")
    end
  end
  context 'session hash' do
    it 'should have all keys' do
      hash = Oauth.new(provider:'twitter',name:'tompng').session_hash
      (Oauth::ACCESSIBLE_ATTRIBUTES-hash.keys).should be_empty
    end
  end
end
