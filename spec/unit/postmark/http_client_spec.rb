require 'spec_helper'

describe Postmark::HttpClient do

  def response_body(status, message = "")
    {"ErrorCode" => status, "Message" => message}.to_json
  end

  let(:api_token) { "provided-postmark-api-token" }
  let(:http_client) { Postmark::HttpClient.new(api_token) }
  subject { http_client }

  context "attr writers" do
    it { expect(subject).to respond_to(:api_token=) }
    it { expect(subject).to respond_to(:api_key=) }
  end

  context "attr readers" do
    it { expect(subject).to respond_to(:http) }
    it { expect(subject).to respond_to(:secure) }
    it { expect(subject).to respond_to(:api_token) }
    it { expect(subject).to respond_to(:api_key) }
    it { expect(subject).to respond_to(:proxy_host) }
    it { expect(subject).to respond_to(:proxy_port) }
    it { expect(subject).to respond_to(:proxy_user) }
    it { expect(subject).to respond_to(:proxy_pass) }
    it { expect(subject).to respond_to(:host) }
    it { expect(subject).to respond_to(:port) }
    it { expect(subject).to respond_to(:path_prefix) }
    it { expect(subject).to respond_to(:http_open_timeout) }
    it { expect(subject).to respond_to(:http_read_timeout) }
    it { expect(subject).to respond_to(:http_ssl_version) }
  end

  context "when it is created without options" do
    its(:api_token) { is_expected.to eq api_token }
    its(:api_key) { is_expected.to eq api_token }
    its(:host) { is_expected.to eq 'api.postmarkapp.com' }
    its(:port) { is_expected.to eq 443 }
    its(:secure) { is_expected.to be true }
    its(:path_prefix) { is_expected.to eq '/' }
    its(:http_read_timeout) { is_expected.to eq 60 }
    its(:http_open_timeout) { is_expected.to eq 60 }

    it 'does not provide a default which utilizes the Net::HTTP default', :skip_ruby_version => ['1.8.7'] do
      http_client = subject.http
      expect(http_client.ssl_version).to eq nil
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
    let(:http_ssl_version) { :TLSv1_2}

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
                                       :http_read_timeout => http_read_timeout,
                                       :http_ssl_version => http_ssl_version) }

    its(:api_token) { is_expected.to eq api_token }
    its(:api_key) { is_expected.to eq api_token }
    its(:secure) { is_expected.to eq secure }
    its(:proxy_host) { is_expected.to eq proxy_host }
    its(:proxy_port) { is_expected.to eq proxy_port }
    its(:proxy_user) { is_expected.to eq proxy_user }
    its(:proxy_pass) { is_expected.to eq proxy_pass }
    its(:host) { is_expected.to eq host }
    its(:port) { is_expected.to eq port }
    its(:path_prefix) { is_expected.to eq path_prefix }
    its(:http_open_timeout) { is_expected.to eq http_open_timeout }
    its(:http_read_timeout) { is_expected.to eq http_read_timeout }
    its(:http_ssl_version) { is_expected.to eq http_ssl_version }

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
      expect(FakeWeb.last_request.method).to eq('POST')
      expect(FakeWeb.last_request.path).to eq('/' + target_path)
    end

    it "raises a custom error when API token authorization fails" do
      FakeWeb.register_uri(:post, target_url, :body => response_body(401), :status => [ "401", "Unauthorized" ])
      expect { subject.post(target_path) }.to raise_error Postmark::InvalidApiKeyError
    end

    it "raises a custom error when sent JSON was not valid" do
      FakeWeb.register_uri(:post, target_url, :body => response_body(422), :status => [ "422", "Invalid" ])
      expect { subject.post(target_path) }.to raise_error Postmark::InvalidMessageError
    end

    it "raises a custom error when server fails to process the request" do
      FakeWeb.register_uri(:post, target_url, :body => response_body(500),
                                              :status => [ "500", "Internal Server Error" ])
      expect { subject.post(target_path) }.to raise_error Postmark::InternalServerError
    end

    it "raises a custom error when the request times out" do
      expect(subject.http).to receive(:post).at_least(:once).and_raise(Timeout::Error)
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
      expect(FakeWeb.last_request.method).to eq('GET')
      expect(FakeWeb.last_request.path).to eq('/' + target_path)
    end

    it "raises a custom error when API token authorization fails" do
      FakeWeb.register_uri(:get, target_url, :body => response_body(401), :status => [ "401", "Unauthorized" ])
      expect { subject.get(target_path) }.to raise_error Postmark::InvalidApiKeyError
    end

    it "raises a custom error when sent JSON was not valid" do
      FakeWeb.register_uri(:get, target_url, :body => response_body(422), :status => [ "422", "Invalid" ])
      expect { subject.get(target_path) }.to raise_error Postmark::InvalidMessageError
    end

    it "raises a custom error when server fails to process the request" do
      FakeWeb.register_uri(:get, target_url, :body => response_body(500),
                                             :status => [ "500", "Internal Server Error" ])
      expect { subject.get(target_path) }.to raise_error Postmark::InternalServerError
    end

    it "raises a custom error when the request times out" do
      expect(subject.http).to receive(:get).at_least(:once).and_raise(Timeout::Error)
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
      expect(FakeWeb.last_request.method).to eq('PUT')
      expect(FakeWeb.last_request.path).to eq('/' + target_path)
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
      expect(subject.http).to receive(:put).at_least(:once).and_raise(Timeout::Error)
      expect { subject.put(target_path) }.to raise_error Postmark::TimeoutError
    end

    it "raises a default error when unknown issue occurs" do
      FakeWeb.register_uri(:put, target_url, :body => response_body(485),
                                             :status => [ "485", "Custom HTTP response status" ])
      expect { subject.put(target_path) }.to raise_error Postmark::UnknownError
    end
  end
end
