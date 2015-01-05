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

  it "can be set as delivery_method" do
    message.delivery_method Mail::Postmark
  end

  it "wraps Postmark.send_through_postmark" do
    Postmark::ApiClient.any_instance.should_receive(:deliver_message).with(message)
    message.delivery_method Mail::Postmark
    message.deliver
  end

  it "returns self by default" do
    Postmark::ApiClient.any_instance.should_receive(:deliver_message).with(message)
    message.delivery_method Mail::Postmark
    message.deliver.should eq message
  end

  it "returns the actual response if :return_response setting is present" do
    Postmark::ApiClient.any_instance.should_receive(:deliver_message).with(message)
    message.delivery_method Mail::Postmark, :return_response => true
    message.deliver.should eq message
  end

  it "allows setting the api token" do
    message.delivery_method Mail::Postmark, :api_token => 'api-token'
    message.delivery_method.settings[:api_token].should == 'api-token'
  end

  it 'uses provided API token' do
    message.delivery_method Mail::Postmark, :api_token => 'api-token'
    Postmark::ApiClient.should_receive(:new).with('api-token', {}).and_return(double(:deliver_message => true))
    message.deliver
  end

  it 'uses API token provided as legacy api_key' do
    message.delivery_method Mail::Postmark, :api_key => 'api-token'
    Postmark::ApiClient.should_receive(:new).with('api-token', {}).and_return(double(:deliver_message => true))
    message.deliver
  end
end