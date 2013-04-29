require 'spec_helper'

describe Postmark::HashHelper do

  describe ".hash_to_postmark" do
    let(:source) { {:from => "support@postmarkapp.com", :reply_to => "contact@wildbit.com"} }
    let(:target) { {"From" => "support@postmarkapp.com", "ReplyTo" => "contact@wildbit.com"} }

    it 'converts Hash keys to Postmark format' do
      subject.to_postmark(source).should == target
    end

    it 'acts idempotentely' do
      subject.to_postmark(target).should == target
    end
  end

end