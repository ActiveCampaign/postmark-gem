require 'spec_helper'

describe Postmark do
  let(:api_token) { double }
  let(:secure) { double }
  let(:proxy_host) { double }
  let(:proxy_port) { double }
  let(:proxy_user) { double }
  let(:proxy_pass) { double }
  let(:host) { double }
  let(:port) { double }
  let(:path_prefix) { double }
  let(:max_retries) { double }

  before do
    subject.api_token = api_token
    subject.secure = secure
    subject.proxy_host = proxy_host
    subject.proxy_port = proxy_port
    subject.proxy_user = proxy_user
    subject.proxy_pass = proxy_pass
    subject.host = host
    subject.port = port
    subject.path_prefix = path_prefix
    subject.max_retries = max_retries
  end

  context "attr readers" do
    it { should respond_to(:secure) }
    it { should respond_to(:api_key) }
    it { should respond_to(:api_token) }
    it { should respond_to(:proxy_host) }
    it { should respond_to(:proxy_port) }
    it { should respond_to(:proxy_user) }
    it { should respond_to(:proxy_pass) }
    it { should respond_to(:host) }
    it { should respond_to(:port) }
    it { should respond_to(:path_prefix) }
    it { should respond_to(:http_open_timeout) }
    it { should respond_to(:http_read_timeout) }
    it { should respond_to(:max_retries) }
  end

  context "attr writers" do
    it { should respond_to(:secure=) }
    it { should respond_to(:api_key=) }
    it { should respond_to(:api_token=) }
    it { should respond_to(:proxy_host=) }
    it { should respond_to(:proxy_port=) }
    it { should respond_to(:proxy_user=) }
    it { should respond_to(:proxy_pass=) }
    it { should respond_to(:host=) }
    it { should respond_to(:port=) }
    it { should respond_to(:path_prefix=) }
    it { should respond_to(:http_open_timeout=) }
    it { should respond_to(:http_read_timeout=) }
    it { should respond_to(:max_retries=) }
    it { should respond_to(:response_parser_class=) }
    it { should respond_to(:api_client=) }
  end

  describe ".response_parser_class" do

    after do
      subject.instance_variable_set(:@response_parser_class, nil)
    end

    it "returns :ActiveSupport when ActiveSupport::JSON is available" do
      subject.response_parser_class.should == :ActiveSupport
    end

    it "returns :Json when ActiveSupport::JSON is not available" do
      hide_const("ActiveSupport::JSON")
      subject.response_parser_class.should == :Json
    end

  end

  describe ".configure" do

    it 'yields itself to the block' do
      expect { |b| subject.configure(&b) }.to yield_with_args(subject)
    end

  end

  describe ".api_client" do
    let(:api_client) { double }

    context "when shared client instance already exists" do

      it 'returns the existing instance' do
        subject.instance_variable_set(:@api_client, api_client)
        subject.api_client.should == api_client
      end

    end

    context "when shared client instance does not exist" do

      it 'creates a new instance of Postmark::ApiClient' do
        Postmark::ApiClient.should_receive(:new).
                            with(api_token,
                                 :secure => secure,
                                 :proxy_host => proxy_host,
                                 :proxy_port => proxy_port,
                                 :proxy_user => proxy_user,
                                 :proxy_pass => proxy_pass,
                                 :host => host,
                                 :port => port,
                                 :path_prefix => path_prefix,
                                 :max_retries => max_retries).
                            and_return(api_client)
        subject.api_client.should == api_client
      end

    end

  end

  describe ".deliver_message" do
    let(:api_client) { double }
    let(:message) { double }

    before do
      subject.api_client = api_client
    end

    it 'delegates the method to the shared api client instance' do
      api_client.should_receive(:deliver_message).with(message)
      subject.deliver_message(message)
    end

    it 'is also accessible as .send_through_postmark' do
      api_client.should_receive(:deliver_message).with(message)
      subject.send_through_postmark(message)
    end
  end

  describe ".deliver_messages" do
    let(:api_client) { double }
    let(:message) { double }

    before do
      subject.api_client = api_client
    end

    it 'delegates the method to the shared api client instance' do
      api_client.should_receive(:deliver_messages).with(message)
      subject.deliver_messages(message)
    end
  end

  describe ".delivery_stats" do
    let(:api_client) { double }

    before do
      subject.api_client = api_client
    end

    it 'delegates the method to the shared api client instance' do
      api_client.should_receive(:delivery_stats)
      subject.delivery_stats
    end
  end  
end