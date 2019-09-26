require 'spec_helper'

describe Postmark::HashHelper do
  describe ".to_postmark" do
    let(:source) { {:from => "support@postmarkapp.com", :reply_to => "contact@wildbit.com"} }
    let(:target) { {"From" => "support@postmarkapp.com", "ReplyTo" => "contact@wildbit.com"} }

    it 'converts Hash keys to Postmark format' do
      expect(subject.to_postmark(source)).to eq target
    end

    it 'acts idempotentely' do
      expect(subject.to_postmark(target)).to eq target
    end
  end

  describe ".to_ruby" do
    let(:source) { {"From" => "support@postmarkapp.com", "ReplyTo" => "contact@wildbit.com"} }
    let(:target) { {:from => "support@postmarkapp.com", :reply_to => "contact@wildbit.com"} }

    it 'converts Hash keys to Ruby format' do
      expect(subject.to_ruby(source)).to eq target
    end

    it 'has compatible mode' do
      expect(subject.to_ruby(source, true)).to eq target.merge(source)
    end

    it 'acts idempotentely' do
      expect(subject.to_ruby(target)).to eq target
    end
  end
end