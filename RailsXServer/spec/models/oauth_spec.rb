require 'spec_helper'

describe Oauth do
  context 'social urls' do
    it 'should return twitter url' do
      Oauth.new(provider:'twitter',name:'tompng').url.should eq("http://twitter.com/tompng")
    end
    it 'should return facebook url' do
      Oauth.new(provider:'facebook',name:'hoge').url.should eq("http://www.facebook.com/hoge")
    end
  end
end
