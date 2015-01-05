require 'spec_helper'

describe "Sending Mail::Messages with delivery_method Mail::Postmark" do
  let(:postmark_message_id_format) { /\w{8}\-\w{4}-\w{4}-\w{4}-\w{12}/ }

  let(:message) {
    Mail.new do
      from "sender@postmarkapp.com"
      to "recipient@postmarkapp.com"
      subject "Mail::Message object"
      body "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do "
           "eiusmod tempor incididunt ut labore et dolore magna aliqua."
      delivery_method Mail::Postmark, :api_token => "POSTMARK_API_TEST",
                                      :http_open_timeout => 15,
                                      :http_read_timeout => 15

    end
  }

  let(:tagged_message) {
    message.tap do |m|
      m.tag "postmark-gem"
    end
  }

  let(:message_with_no_body) {
    Mail.new do
      from "sender@postmarkapp.com"
      to "recipient@postmarkapp.com"
      delivery_method Mail::Postmark, :api_token => "POSTMARK_API_TEST",
                                      :http_open_timeout => 15,
                                      :http_read_timeout => 15
    end
  }

  let(:message_with_attachment) {
    message.tap do |msg|
      msg.attachments["test.gif"] = File.read(File.join(File.dirname(__FILE__), '..', 'data', 'empty.gif'))
    end
  }

  let(:message_with_invalid_to) {
    Mail.new do
      from "sender@postmarkapp.com"
      to "@postmarkapp.com"
      delivery_method Mail::Postmark, :api_token => "POSTMARK_API_TEST",
                                      :http_open_timeout => 15,
                                      :http_read_timeout => 15
    end
  }

  it 'delivers a plain text message' do
    expect { message.deliver }.to change{message.delivered?}.to(true)
  end

  it 'updates a message object with Message-ID' do
    expect { message.deliver }.
        to change{message['Message-ID'].to_s}.to(postmark_message_id_format)
  end

  it 'updates a message object with full postmark response' do
    expect { message.deliver }.
        to change{message.postmark_response}.from(nil)
  end

  it 'delivers a tagged message' do
    expect { tagged_message.deliver }.
        to change{message.delivered?}.to(true)
  end

  it 'delivers a message with attachment' do
    expect { message_with_attachment.deliver }.
        to change{message_with_attachment.delivered?}.to(true)
  end

  it 'fails to deliver a message without body' do
    expect { message_with_no_body.deliver! }.
        to raise_error(Postmark::InvalidMessageError)
    message_with_no_body.should_not be_delivered
  end

  it 'fails to deliver a message with invalid To address' do
    expect { message_with_invalid_to.deliver! }.
        to raise_error(Postmark::InvalidMessageError)
    message_with_invalid_to.should_not be_delivered
  end
end