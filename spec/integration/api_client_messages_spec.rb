require 'spec_helper'

describe "Sending Mail::Messages with Postmark::ApiClient" do
  let(:postmark_message_id_format) { /\w{8}\-\w{4}-\w{4}-\w{4}-\w{12}/ }
  let(:api_client) {
    Postmark::ApiClient.new('POSTMARK_API_TEST',
                            :http_open_timeout => 15,
                            :http_read_timeout => 15)
  }

  let(:message) {
    Mail.new do
      from "sender@postmarkapp.com"
      to "recipient@postmarkapp.com"
      subject "Mail::Message object"
      body "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do "
           "eiusmod tempor incididunt ut labore et dolore magna aliqua."
    end
  }

  let(:message_with_no_body) {
    Mail.new do
      from "sender@postmarkapp.com"
      to "recipient@postmarkapp.com"
    end
  }

  let(:message_with_attachment) {
    message.tap do |msg|
      msg.attachments["test.gif"] = File.read(empty_gif_path)
    end
  }

  let(:message_with_invalid_to) {
    Mail.new do
      from "sender@postmarkapp.com"
      to "@postmarkapp.com"
    end
  }

  let(:valid_messages) { [message, message.dup] }
  let(:partially_valid_messages) { [message, message.dup, message_with_no_body] }
  let(:invalid_messages) { [message_with_no_body, message_with_no_body.dup] }

  context 'invalid API code' do
    it "doesn't deliver messages" do
      expect {
        Postmark::ApiClient.new('INVALID').deliver_message(message) rescue Postmark::InvalidApiKeyError
      }.to change{message.delivered?}.to(false)
    end
  end

  context "message by message" do
    it 'delivers a plain text message' do
      api_client.deliver_message(message).should have_key(:message_id)
    end

    it 'updates a message object with Message-ID' do
      api_client.deliver_message(message)[:message_id].
          should =~ postmark_message_id_format
    end

    it 'returns full Postmark response' do
      api_client.deliver_message(message).should be_a Hash
    end

    it 'delivers a message with attachment' do
      api_client.deliver_message(message_with_attachment).
          should have_key(:message_id)
    end

    it 'fails to deliver a message without body' do
      expect { api_client.deliver_message(message_with_no_body) }.
          to raise_error(Postmark::InvalidMessageError)
    end

    it 'fails to deliver a message with invalid To address' do
      expect { api_client.deliver_message(message_with_invalid_to) }.
          to raise_error(Postmark::InvalidMessageError)
    end
  end

  context "in batches" do
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

    it 'returns as many responses as many messages were sent' do
      api_client.deliver_messages(valid_messages).count.should == valid_messages.count
    end

    context "given custom max_batch_size" do
      before do
        api_client.max_batch_size = 1
      end

      it 'updates delivered messages with related Postmark responses' do
        api_client.deliver_messages(valid_messages)

        expect(valid_messages.all? { |m| m.postmark_response["To"] == m.to[0] }).
            to be_true
      end

      it 'returns as many responses as many messages were sent' do
        api_client.deliver_messages(valid_messages).count.should == valid_messages.count
      end
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