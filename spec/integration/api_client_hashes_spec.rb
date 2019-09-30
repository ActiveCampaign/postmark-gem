require 'spec_helper'

describe "Sending messages as Ruby hashes with Postmark::ApiClient" do
  let(:message_id_format) {/<.+@.+>/}
  let(:postmark_message_id_format) {/\w{8}\-\w{4}-\w{4}-\w{4}-\w{12}/}
  let(:api_client) {Postmark::ApiClient.new('POSTMARK_API_TEST', :http_open_timeout => 15, :http_read_timeout => 15)}

  let(:message) {
    {
        :from => "sender@postmarkapp.com",
        :to => "recipient@postmarkapp.com",
        :subject => "Mail::Message object",
        :text_body => "Lorem ipsum dolor sit amet, consectetur adipisicing elit, " \
                    "sed do eiusmod tempor incididunt ut labore et dolore " \
                    "magna aliqua."
    }
  }

  let(:message_with_no_body) {
    {
        :from => "sender@postmarkapp.com",
        :to => "recipient@postmarkapp.com",
    }
  }

  let(:message_with_attachment) {
    message.tap do |m|
      m[:attachments] = [File.open(empty_gif_path)]
    end
  }

  let(:message_with_invalid_to) {{:from => "sender@postmarkapp.com", :to => "@postmarkapp.com"}}
  let(:valid_messages) {[message, message.dup]}
  let(:partially_valid_messages) {[message, message.dup, message_with_no_body]}
  let(:invalid_messages) {[message_with_no_body, message_with_no_body.dup]}

  context "single message" do
    it 'plain text message' do
      expect(api_client.deliver(message)).to have_key(:message_id)
    end

    it 'message with attachment' do
      expect(api_client.deliver(message_with_attachment)).to have_key(:message_id)
    end

    it 'response Message-ID' do
      expect(api_client.deliver(message)[:message_id]).to be =~ postmark_message_id_format
    end

    it 'response is Hash' do
      expect(api_client.deliver(message)).to be_a Hash
    end

    it 'fails to deliver a message without body' do
      expect {api_client.deliver(message_with_no_body)}.to raise_error(Postmark::InvalidMessageError)
    end

    it 'fails to deliver a message with invalid To address' do
      expect {api_client.deliver(message_with_invalid_to)}.to raise_error(Postmark::InvalidMessageError)
    end
  end

  context "batch message" do
    it 'response messages count' do
      expect(api_client.deliver_in_batches(valid_messages).count).to eq valid_messages.count
    end

    context "custom max_batch_size" do
      before do
        api_client.max_batch_size = 1
      end

      it 'response message count' do
        expect(api_client.deliver_in_batches(valid_messages).count).to eq valid_messages.count
      end
    end

    it 'partially delivers a batch of partially valid Mail::Message objects' do
      response = api_client.deliver_in_batches(partially_valid_messages)
      expect(response).to satisfy {|r| r.count {|mr| mr[:error_code].to_i.zero?} == 2}
    end

    it "doesn't deliver a batch of invalid Mail::Message objects" do
      response = api_client.deliver_in_batches(invalid_messages)
      expect(response).to satisfy {|r| r.all? {|mr| !!mr[:error_code]}}
    end
  end
end