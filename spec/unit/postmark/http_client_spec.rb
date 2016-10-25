require 'spec_helper'

describe Postmark::HttpClient do

  def response_body(status, message = "")
    body = {"ErrorCode" => status, "Message" => message}.to_json
  end

  let(:api_token) { "provided-postmark-api-token" }
  let(:http_client) { Postmark::HttpClient.new(api_token) }
  subject { http_client }

  context "attr writers" do
    it { should respond_to(:api_token=) }
    it { should respond_to(:api_key=) }
  end

  context "attr readers" do
    it { should respond_to(:http) }
    it { should respond_to(:secure) }
    it { should respond_to(:api_token) }
    it { should respond_to(:api_key) }
    it { should respond_to(:proxy_host) }
    it { should respond_to(:proxy_port) }
    it { should respond_to(:proxy_user) }
    it { should respond_to(:proxy_pass) }
    it { should respond_to(:host) }
    it { should respond_to(:port) }
    it { should respond_to(:path_prefix) }
    it { should respond_to(:http_open_timeout) }
    it { should respond_to(:http_read_timeout) }
  end

  context "when it is created without options" do
    its(:api_token) { should eq api_token }
    its(:api_key) { should eq api_token }
    its(:host) { should eq 'api.postmarkapp.com' }
    its(:port) { should eq 443 }
    its(:secure) { should be_true }
    its(:path_prefix) { should eq '/' }
    its(:http_read_timeout) { should eq 15 }
    its(:http_open_timeout) { should eq 5 }

    it 'uses TLS encryption', :skip_ruby_version => ['1.8.7'] do
      http_client = subject.http
      http_client.ssl_version.should == :TLSv1
    end
  end

  context "when it is created with options" do
    let(:secure) { true }
    let(:proxy_host) { "providedproxyhostname.com" }
    let(:proxy_port) { 42 }
    let(:proxy_user) { "provided proxy user" }
    let(:proxy_pass) { "provided proxy pass" }
    let(:host) { "providedhostname.org" }
    let(:port) { 4443 }
    let(:path_prefix) { "/provided/path/prefix" }
    let(:http_open_timeout) { 42 }
    let(:http_read_timeout) { 42 }

    subject { Postmark::HttpClient.new(api_token,
                                       :secure => secure,
                                       :proxy_host => proxy_host,
                                       :proxy_port => proxy_port,
                                       :proxy_user => proxy_user,
                                       :proxy_pass => proxy_pass,
                                       :host => host,
                                       :port => port,
                                       :path_prefix => path_prefix,
                                       :http_open_timeout => http_open_timeout,
                                       :http_read_timeout => http_read_timeout) }

    its(:api_token) { should eq api_token }
    its(:api_key) { should eq api_token }
    its(:secure) { should == secure }
    its(:proxy_host) { should == proxy_host }
    its(:proxy_port) { should == proxy_port }
    its(:proxy_user) { should == proxy_user }
    its(:proxy_pass) { should == proxy_pass }
    its(:host) { should == host }
    its(:port) { should == port }
    its(:path_prefix) { should == path_prefix }
    its(:http_open_timeout) { should == http_open_timeout }
    its(:http_read_timeout) { should == http_read_timeout }

    it 'uses port 80 for plain HTTP connections' do
      expect(Postmark::HttpClient.new(api_token, :secure => false).port).to eq(80)
    end

    it 'uses port 443 for secure HTTP connections' do
      expect(Postmark::HttpClient.new(api_token, :secure => true).port).to eq(443)
    end

    it 'respects port over secure option' do
      client = Postmark::HttpClient.new(api_token, :port => 80, :secure => true)
      expect(client.port).to eq(80)
      expect(client.protocol).to eq('https')
    end
  end

  describe "#post" do
    let(:target_path) { "path/on/server" }
    let(:target_url) { "https://api.postmarkapp.com/#{target_path}" }

    it "sends a POST request to provided URI" do
      FakeWeb.register_uri(:post, target_url, :body => response_body(200))
      subject.post(target_path)
      FakeWeb.should have_requested(:post, target_url)
    end

    it "raises a custom error when API token authorization fails" do
      FakeWeb.register_uri(:post, target_url, :body => response_body(401),
                                              :status => [ "401", "Unauthorized" ])
      expect { subject.post(target_path) }.to raise_error Postmark::InvalidApiKeyError
    end

    it "raises a custom error when sent JSON was not valid" do
      FakeWeb.register_uri(:post, target_url, :body => response_body(422),
                                              :status => [ "422", "Invalid" ])
      expect { subject.post(target_path) }.to raise_error Postmark::InvalidMessageError
    end

    it "raises a custom error when server fails to process the request" do
      FakeWeb.register_uri(:post, target_url, :body => response_body(500),
                                              :status => [ "500", "Internal Server Error" ])
      expect { subject.post(target_path) }.to raise_error Postmark::InternalServerError
    end

    it "raises a custom error when the request times out" do
      subject.http.should_receive(:post).at_least(:once).
                                             and_raise(Timeout::Error)
      expect { subject.post(target_path) }.to raise_error Postmark::TimeoutError
    end

    it "raises a default error when unknown issue occurs" do
      FakeWeb.register_uri(:post, target_url, :body => response_body(485),
                                              :status => [ "485", "Custom HTTP response status" ])
      expect { subject.post(target_path) }.to raise_error Postmark::UnknownError
    end
    
  end

  describe "#get" do
    let(:target_path) { "path/on/server" }
    let(:target_url) { "https://api.postmarkapp.com/#{target_path}" }

    it "sends a GET request to provided URI" do
      FakeWeb.register_uri(:get, target_url, :body => response_body(200))
      subject.get(target_path)
      FakeWeb.should have_requested(:get, target_url)
    end

    it "raises a custom error when API token authorization fails" do
      FakeWeb.register_uri(:get, target_url, :body => response_body(401),
                                              :status => [ "401", "Unauthorized" ])
      expect { subject.get(target_path) }.to raise_error Postmark::InvalidApiKeyError
    end

    it "raises a custom error when sent JSON was not valid" do
      FakeWeb.register_uri(:get, target_url, :body => response_body(422),
                                             :status => [ "422", "Invalid" ])
      expect { subject.get(target_path) }.to raise_error Postmark::InvalidMessageError
    end

    it "raises a custom error when server fails to process the request" do
      FakeWeb.register_uri(:get, target_url, :body => response_body(500),
                                             :status => [ "500", "Internal Server Error" ])
      expect { subject.get(target_path) }.to raise_error Postmark::InternalServerError
    end

    it "raises a custom error when the request times out" do
      subject.http.should_receive(:get).at_least(:once).and_raise(Timeout::Error)
      expect { subject.get(target_path) }.to raise_error Postmark::TimeoutError
    end

    it "raises a default error when unknown issue occurs" do
      FakeWeb.register_uri(:get, target_url, :body => response_body(485),
                                             :status => [ "485", "Custom HTTP response status" ])
      expect { subject.get(target_path) }.to raise_error Postmark::UnknownError
    end
    
  end

  describe "#put" do
    let(:target_path) { "path/on/server" }
    let(:target_url) { "https://api.postmarkapp.com/#{target_path}" }

    it "sends a PUT request to provided URI" do
      FakeWeb.register_uri(:put, target_url, :body => response_body(200))
      subject.put(target_path)
      FakeWeb.should have_requested(:put, target_url)
    end

    it "raises a custom error when API token authorization fails" do
      FakeWeb.register_uri(:put, target_url, :body => response_body(401),
                                             :status => [ "401", "Unauthorized" ])
      expect { subject.put(target_path) }.to raise_error Postmark::InvalidApiKeyError
    end

    it "raises a custom error when sent JSON was not valid" do
      FakeWeb.register_uri(:put, target_url, :body => response_body(422),
                                             :status => [ "422", "Invalid" ])
      expect { subject.put(target_path) }.to raise_error Postmark::InvalidMessageError
    end

    it "raises a custom error when server fails to process the request" do
      FakeWeb.register_uri(:put, target_url, :body => response_body(500),
                                             :status => [ "500", "Internal Server Error" ])
      expect { subject.put(target_path) }.to raise_error Postmark::InternalServerError
    end

    it "raises a custom error when the request times out" do
      subject.http.should_receive(:put).at_least(:once).and_raise(Timeout::Error)
      expect { subject.put(target_path) }.to raise_error Postmark::TimeoutError
    end

    it "raises a default error when unknown issue occurs" do
      FakeWeb.register_uri(:put, target_url, :body => response_body(485),
                                             :status => [ "485", "Custom HTTP response status" ])
      expect { subject.put(target_path) }.to raise_error Postmark::UnknownError
    end
    
  end
end