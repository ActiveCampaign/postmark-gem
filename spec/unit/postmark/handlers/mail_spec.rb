require 'spec_helper'

describe Mail::Postmark do
  let(:message) do
    Mail.new do
      from    "sheldon@bigbangtheory.com"
      to      "lenard@bigbangtheory.com"
      subject "Hello!"
      body    "Hello Sheldon!"
    end
  end

  before do
    message.delivery_method Mail::Postmark
  end

  subject(:handler) { message.delivery_method }

  it "can be set as delivery_method" do
    message.delivery_method Mail::Postmark

    is_expected.to be_a(Mail::Postmark)
  end

  describe '#deliver!' do
    it "returns self by default" do
      expect_any_instance_of(Postmark::ApiClient).to receive(:deliver_message).with(message)
      expect(message.deliver).to eq message
    end

    it "returns the actual response if :return_response setting is present" do
      expect_any_instance_of(Postmark::ApiClient).to receive(:deliver_message).with(message)
      message.delivery_method Mail::Postmark, :return_response => true
      expect(message.deliver).to eq message
    end

    it "allows setting the api token" do
      message.delivery_method Mail::Postmark, :api_token => 'api-token'
      expect(message.delivery_method.settings[:api_token]).to eq 'api-token'
    end

    it 'uses provided API token' do
      message.delivery_method Mail::Postmark, :api_token => 'api-token'
      expect(Postmark::ApiClient).to receive(:new).with('api-token', {}).and_return(double(:deliver_message => true))
      message.deliver
    end

    it 'uses API token provided as legacy api_key' do
      message.delivery_method Mail::Postmark, :api_key => 'api-token'
      expect(Postmark::ApiClient).to receive(:new).with('api-token', {}).and_return(double(:deliver_message => true))
      message.deliver
    end

    context 'when sending a pre-rendered message' do
      it "uses ApiClient#deliver_message to send the message" do
        expect_any_instance_of(Postmark::ApiClient).to receive(:deliver_message).with(message)
        message.deliver
      end
    end

    context 'when sending a Postmark template' do
      let(:message) do
        Mail.new do
          from            "sheldon@bigbangtheory.com"
          to              "lenard@bigbangtheory.com"
          template_alias  "hello"
          template_model  :name => "Sheldon"
        end
      end

      it 'uses ApiClient#deliver_message_with_template to send the message' do
        expect_any_instance_of(Postmark::ApiClient).to receive(:deliver_message_with_template).with(message)
        message.deliver
      end
    end
  end

  describe '#api_client' do
    subject { handler.api_client }

    it { is_expected.to be_a(Postmark::ApiClient) }
  end
end
