require 'spec_helper'

describe Postmark::HashHelper do
  describe ".to_postmark" do
    let(:source) { {:from => "support@postmarkapp.com", :reply_to => "contact@wildbit.com"} }
    let(:target) { {"From" => "support@postmarkapp.com", "ReplyTo" => "contact@wildbit.com"} }

    it 'converts Hash keys to Postmark format' do
      subject.to_postmark(source).should == target
    end

    it 'acts idempotentely' do
      subject.to_postmark(target).should == target
    end
  end

  describe ".to_ruby" do
    let(:source) { {"From" => "support@postmarkapp.com", "ReplyTo" => "contact@wildbit.com"} }
    let(:target) { {:from => "support@postmarkapp.com", :reply_to => "contact@wildbit.com"} }

    it 'converts Hash keys to Ruby format' do
      subject.to_ruby(source).should == target
    end

    it 'has compatible mode' do
      subject.to_ruby(source, true).should == target.merge(source)
    end

    it 'acts idempotentely' do
      subject.to_ruby(target).should == target
    end
  end

end