require 'spec_helper'

describe "Sending emails with Postmark" do
  let(:postmark_message_id_format) { /\w{8}\-\w{4}-\w{4}-\w{4}-\w{12}/ }

  let(:message) {
    Mail.new do
      from "sender@postmarkapp.com"
      to "recipient@postmarkapp.com"
      subject "Mail::Message object"
      body "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do "
           "eiusmod tempor incididunt ut labore et dolore magna aliqua."
      delivery_method Mail::Postmark, :api_key => "POSTMARK_API_TEST"
    end
  }

  let(:message_with_no_body) {
    Mail.new do
      from "sender@postmarkapp.com"
      to "recipient@postmarkapp.com"
      delivery_method Mail::Postmark, :api_key => "POSTMARK_API_TEST"
    end
  }

  context "Mail::Postmark delivery method" do

    let(:message_with_attachment) {
      message.tap do |msg|
        msg.attachments["test.gif"] = File.read(File.join(File.dirname(__FILE__), '..', 'data', 'empty.gif'))
      end
    }

    let(:message_with_invalid_to) {
      Mail.new do
        from "sender@postmarkapp.com"
        to "@postmarkapp.com"
        delivery_method Mail::Postmark, :api_key => "POSTMARK_API_TEST"
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
      message_with_no_body.should_not be_delivered
    end
  end

  context "batch delivery" do
    let(:api_client) { Postmark::ApiClient.new('POSTMARK_API_TEST') }
    let(:valid_messages) { [message, message.dup] }
    let(:partially_valid_messages) { [message, message.dup, message_with_no_body] }
    let(:invalid_messages) { [message_with_no_body, message_with_no_body.dup] }

    it 'delivers a batch of valid Mail::Message objects' do
      expect { api_client.deliver_messages(valid_messages) }.
          to change{valid_messages.all? { |m| m.delivered? }}.
             to true
    end

    it 'updates delivered messages with Message-IDs' do
      api_client.deliver_messages(valid_messages)

      expect(valid_messages.all? { |m| m.message_id =~ postmark_message_id_format }).
          to be_true
    end

    it 'updates delivered messages with related Postmark responses' do
      api_client.deliver_messages(valid_messages)

      expect(valid_messages.all? { |m| m.postmark_response["To"] == m.to[0] }).
          to be_true
    end

    it 'partially delivers a batch of partially valid Mail::Message objects' do
      expect { api_client.deliver_messages(partially_valid_messages) }.
          to change{partially_valid_messages.select { |m| m.delivered? }.count}.
             to 2
    end

    it "doesn't deliver a batch of invalid Mail::Message objects" do
      expect { api_client.deliver_messages(invalid_messages) }.
          to change{invalid_messages.all? { |m| m.delivered? == false }}.
             to true

      invalid_messages.should satisfy { |ms| ms.all? { |m| !!m.postmark_response }}
    end

  end
end