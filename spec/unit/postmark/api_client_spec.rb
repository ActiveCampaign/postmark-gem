require 'spec_helper'

describe Postmark::ApiClient do

  let(:api_key) { "provided-api-key" }
  let(:max_retries) { 42 }
  let(:message_hash) {
    {
      :from => "support@postmarkapp.com"
    }
  }
  let(:message) {
    Mail.new do
      from "support@postmarkapp.com"
      delivery_method Mail::Postmark
    end
  }

  let(:api_client) { Postmark::ApiClient.new(api_key) }
  subject { api_client }

  context "attr readers" do
    it { should respond_to(:http_client) }
    it { should respond_to(:max_retries) }
  end

  context "when it's created without options" do

    its(:max_retries) { should eq 3 }

  end

  context "when it's created with user options" do

    subject { Postmark::ApiClient.new(api_key, :max_retries => max_retries,
                                               :foo => :bar)}

    its(:max_retries) { should eq max_retries }

    it 'passes other options to HttpClient instance' do
      Postmark::HttpClient.should_receive(:new).with(api_key, :foo => :bar)
      subject.should be
    end

  end

  describe "#api_key=" do

    let(:api_key) { "new-api-key-value" }

    it 'assigns the api key to the http client instance' do
      subject.api_key = api_key
      subject.http_client.api_key.should == api_key
    end

  end

  describe "#deliver" do
    let(:email) { Postmark::MessageHelper.to_postmark(message_hash) }
    let(:email_json) { Postmark::Json.encode(email) }
    let(:http_client) { subject.http_client }
    let(:response) { {"MessageID" => 42} }

    it 'converts message hash to Postmark format and posts it to /email' do
      http_client.should_receive(:post).with('email', email_json) { response }
      subject.deliver(message_hash)
    end

    it 'retries 3 times' do
      2.times do
        http_client.should_receive(:post).and_raise(Postmark::InternalServerError)
      end
      http_client.should_receive(:post) { response }
      expect { subject.deliver(message_hash) }.not_to raise_error
    end

    it 'converts response to ruby format' do
      http_client.should_receive(:post).with('email', email_json) { response }
      r = subject.deliver(message_hash)
      r.should have_key(:message_id)
    end
  end

  describe "#deliver_in_batches" do
    let(:email) { Postmark::MessageHelper.to_postmark(message_hash) }
    let(:emails) { [email, email, email] }
    let(:emails_json) { Postmark::Json.encode(emails) }
    let(:http_client) { subject.http_client }
    let(:response) { [{'ErrorCode' => 0}, {'ErrorCode' => 0}, {'ErrorCode' => 0}] }

    it 'turns array of messages into a JSON document and posts it to /email/batch' do
      http_client.should_receive(:post).with('email/batch', emails_json) { response }
      subject.deliver_in_batches([message_hash, message_hash, message_hash])
    end

    it 'converts response to ruby format' do
      http_client.should_receive(:post).with('email/batch', emails_json) { response }
      response = subject.deliver_in_batches([message_hash, message_hash, message_hash])
      response.first.should have_key(:error_code)
    end
  end

  describe "#deliver_message" do
    let(:email) { message.to_postmark_hash }
    let(:email_json) { JSON.dump(email) }
    let(:http_client) { subject.http_client }

    it 'turns message into a JSON document and posts it to /email' do
      http_client.should_receive(:post).with('email', email_json)
      subject.deliver_message(message)
    end

    it "should retry 3 times" do
      2.times do
        http_client.should_receive(:post).and_raise(Postmark::InternalServerError)
      end
      http_client.should_receive(:post)
      expect { subject.deliver_message(message) }.not_to raise_error
    end

    it "should retry on timeout" do
      http_client.should_receive(:post).and_raise(Postmark::TimeoutError)
      http_client.should_receive(:post)
      expect { subject.deliver_message(message) }.not_to raise_error
    end

  end

  describe "#deliver_messages" do

    let(:email) { message.to_postmark_hash }
    let(:emails) { [email, email, email] }
    let(:emails_json) { JSON.dump(emails) }
    let(:http_client) { subject.http_client }
    let(:response) { [{}, {}, {}] }

    it 'turns array of messages into a JSON document and posts it to /email/batch' do
      http_client.should_receive(:post).with('email/batch', emails_json) { response }
      subject.deliver_messages([message, message, message])
    end

    it "should retry 3 times" do
      2.times do
        http_client.should_receive(:post).and_raise(Postmark::InternalServerError)
      end
      http_client.should_receive(:post) { response }
      expect { subject.deliver_messages([message, message, message]) }.not_to raise_error
    end

    it "should retry on timeout" do
      http_client.should_receive(:post).and_raise(Postmark::TimeoutError)
      http_client.should_receive(:post) { response }
      expect { subject.deliver_messages([message, message, message]) }.not_to raise_error
    end

  end

  describe "#delivery_stats" do
    let(:http_client) { subject.http_client }
    let(:response) { {"Bounces" => [{"Foo" => "Bar"}]} }

    it 'requests data at /deliverystats' do
      http_client.should_receive(:get).with("deliverystats") { response }
      subject.delivery_stats.should have_key(:bounces)
    end
  end

  describe "#get_bounces" do
    let(:http_client) { subject.http_client }
    let(:options) { {:foo => :bar} }
    let(:response) { {"Bounces" => []} }

    it 'requests data at /bounces' do
      http_client.should_receive(:get).with("bounces", options) { response }
      subject.get_bounces(options).should be_an Array
    end
  end

  describe "#get_bounced_tags" do
    let(:http_client) { subject.http_client }

    it 'requests data at /bounces/tags' do
      http_client.should_receive(:get).with("bounces/tags")
      subject.get_bounced_tags
    end
  end

  describe "#get_bounce" do
    let(:http_client) { subject.http_client }
    let(:id) { 42 }

    it 'requests a single bounce by ID at /bounces/:id' do
      http_client.should_receive(:get).with("bounces/#{id}")
      subject.get_bounce(id)
    end
  end

  describe "#dump_bounce" do
    let(:http_client) { subject.http_client }
    let(:id) { 42 }

    it 'requests a specific bounce data at /bounces/:id/dump' do
      http_client.should_receive(:get).with("bounces/#{id}/dump")
      subject.dump_bounce(id)
    end
  end

  describe "#activate_bounce" do
    let(:http_client) { subject.http_client }
    let(:id) { 42 }
    let(:response) { {"Bounce" => {}} }

    it 'activates a specific bounce by sending a PUT request to /bounces/:id/activate' do
      http_client.should_receive(:put).with("bounces/#{id}/activate") { response }
      subject.activate_bounce(id)
    end
  end

  describe "#server_info" do
    let(:http_client) { subject.http_client }
    let(:response) { {"Name" => "Testing",
                      "Color" => "blue",
                      "InboundHash" => "c2425d77f74f8643e5f6237438086c81",
                      "SmtpApiActivated" => true} }

    it 'requests server info from Postmark and converts it to ruby format' do
      http_client.should_receive(:get).with('server') { response }
      subject.server_info.should have_key(:inbound_hash)
    end
  end

  describe "#update_server_info" do
    let(:http_client) { subject.http_client }
    let(:response) { {"Name" => "Testing",
                      "Color" => "blue",
                      "InboundHash" => "c2425d77f74f8643e5f6237438086c81",
                      "SmtpApiActivated" => false} }
    let(:update) { {:smtp_api_activated => false} }

    it 'updates server info in Postmark and converts it to ruby format' do
      http_client.should_receive(:post).with('server', anything) { response }
      subject.update_server_info(update)[:smtp_api_activated].should be_false
    end
  end

end