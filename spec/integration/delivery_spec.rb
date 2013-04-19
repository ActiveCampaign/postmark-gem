require 'spec_helper'

describe "Sending emails with Postmark" do
  subject { Postmark::ApiClient.new("POSTMARK_API_TEST") }

  context "Mail::Message delivery" do
    let(:message) {
      Mail.new do
        from "sender@postmarkapp.com"
        to "recipient@postmarkapp.com"
        subject "Delivers a Mail::Message object"
        body "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do "
             "eiusmod tempor incididunt ut labore et dolore magna aliqua."
      end
    }

    let(:message_with_attachment) {
      message.tap do |msg|
        msg.attachments["test.gif"] = "\x47\x49\x46\x38\x39\x61\x01\x00\x01\x00\xf0\x01\x00\xff\xff\xff\x00\x00\x00\x21\xf9\x04\x01\x0a\x00\x00\x00\x2c\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02\x44\x01\x00\x3b"
      end
    }

    it 'should deliver a Mail::Message object' do
      subject.deliver_message(message).should be
    end

    it 'should deliver a Mail::Message object with attachment' do
      subject.deliver_message(message_with_attachment).should be
    end

    it 'should deliver a batch of Mail::Message objects' do
      subject.deliver_messages([message, message_with_attachment, message]).should be
    end
  end
end