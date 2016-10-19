require 'spec_helper'

describe Postmark::AccountApiClient do

  let(:api_token) { 'abcd-efgh' }
  subject { Postmark::AccountApiClient}

  it 'can be created with an API token' do
    expect { subject.new(api_token) }.not_to raise_error
  end

  it 'can be created with an API token and options hash' do
    expect { subject.new(api_token, :http_read_timeout => 5) }.not_to raise_error
  end

  context 'instance' do

    subject { Postmark::AccountApiClient.new(api_token) }

    it 'uses the auth header specific for Account API' do
      auth_header = subject.http_client.auth_header_name
      expect(auth_header).to eq('X-Postmark-Account-Token')
    end

    describe '#senders' do

      let(:response) {
        {
          'TotalCount' => 10, 'SenderSignatures' => [{}, {}]
        }
      }

      it 'is aliased as #signatures' do
        expect(subject).to respond_to(:signatures)
        expect(subject).to respond_to(:signatures).with(1).argument
      end

      it 'returns an enumerator' do
        expect(subject.senders).to be_kind_of(Enumerable)
      end

      it 'lazily loads senders' do
        allow(subject.http_client).to receive(:get).
            with('senders', an_instance_of(Hash)).and_return(response)
        subject.senders.take(1000)
      end

    end

    describe '#get_senders' do

      let(:response) {
        {
          "TotalCount" => 1,
          "SenderSignatures" => [{
            "Domain" => "example.com",
            "EmailAddress" => "someone@example.com",
            "ReplyToEmailAddress" => "info@example.com",
            "Name" => "Example User",
            "Confirmed" => true,
            "ID" => 8139
          }]
        }
      }

      it 'is aliased as #get_signatures' do
        expect(subject).to respond_to(:get_signatures).with(1).argument
      end

      it 'performs a GET request to /senders endpoint' do
        allow(subject.http_client).to receive(:get).
            with('senders', :offset => 0, :count => 30).
            and_return(response)
        subject.get_senders
      end

      it 'formats the keys of returned list of senders' do
        allow(subject.http_client).to receive(:get).and_return(response)
        keys = subject.get_senders.map { |s| s.keys }.flatten
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end

      it 'accepts offset and count options' do
        allow(subject.http_client).to receive(:get).
            with('senders', :offset => 10, :count => 42).
            and_return(response)
        subject.get_senders(:offset => 10, :count => 42)
      end

    end

    describe '#get_senders_count' do

      let(:response) { {'TotalCount' => 42} }

      it 'is aliased as #get_signatures_count' do
        expect(subject).to respond_to(:get_signatures_count)
        expect(subject).to respond_to(:get_signatures_count).with(1).argument
      end

      it 'returns a total number of senders' do
        allow(subject.http_client).to receive(:get).
            with('senders', an_instance_of(Hash)).and_return(response)
        expect(subject.get_senders_count).to eq(42)
      end

    end

    describe '#get_sender' do

      let(:response) {
        {
          "Domain" => "example.com",
          "EmailAddress" => "someone@example.com",
          "ReplyToEmailAddress" => "info@example.com",
          "Name" => "Example User",
          "Confirmed" => true,
          "ID" => 8139
        }
      }

      it 'is aliased as #get_signature' do
        expect(subject).to respond_to(:get_signature).with(1).argument
      end

      it 'performs a GET request to /senders/:id endpoint' do
        allow(subject.http_client).to receive(:get).with("senders/42").
                                                    and_return(response)
        subject.get_sender(42)
      end

      it 'formats the keys of returned response' do
        allow(subject.http_client).to receive(:get).and_return(response)
        keys = subject.get_sender(42).keys
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end
    end

    describe '#create_sender' do

      let(:response) {
        {
          "Domain" => "example.com",
          "EmailAddress" => "someone@example.com",
          "ReplyToEmailAddress" => "info@example.com",
          "Name" => "Example User",
          "Confirmed" => true,
          "ID" => 8139
        }
      }

      it 'is aliased as #create_signature' do
        expect(subject).to respond_to(:create_signature).with(1).argument
      end

      it 'performs a POST request to /senders endpoint' do
        allow(subject.http_client).to receive(:post).
            with("senders", an_instance_of(String)).and_return(response)
        subject.create_sender(:name => 'Chris Nagele')
      end

      it 'converts the sender attributes names to camel case' do
        allow(subject.http_client).to receive(:post).
            with("senders", {'FooBar' => 'bar'}.to_json).and_return(response)
        subject.create_sender(:foo_bar => 'bar')
      end

      it 'formats the keys of returned response' do
        allow(subject.http_client).to receive(:post).and_return(response)
        keys = subject.create_sender(:foo => 'bar').keys
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end
    end

    describe '#update_sender' do

      let(:response) {
        {
          "Domain" => "example.com",
          "EmailAddress" => "someone@example.com",
          "ReplyToEmailAddress" => "info@example.com",
          "Name" => "Example User",
          "Confirmed" => true,
          "ID" => 8139
        }
      }

      it 'is aliased as #update_signature' do
        expect(subject).to respond_to(:update_signature).with(1).argument
        expect(subject).to respond_to(:update_signature).with(2).arguments
      end

      it 'performs a PUT request to /senders/:id endpoint' do
        allow(subject.http_client).to receive(:put).
            with('senders/42', an_instance_of(String)).and_return(response)
        subject.update_sender(42, :name => 'Chris Nagele')
      end

      it 'converts the sender attributes names to camel case' do
        allow(subject.http_client).to receive(:put).
            with('senders/42', {'FooBar' => 'bar'}.to_json).and_return(response)
        subject.update_sender(42, :foo_bar => 'bar')
      end

      it 'formats the keys of returned response' do
        allow(subject.http_client).to receive(:put).and_return(response)
        keys = subject.update_sender(42, :foo => 'bar').keys
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end

    end

    describe '#resend_sender_confirmation' do

      let(:response) {
        {
          "ErrorCode" => 0,
          "Message" => "Confirmation email for Sender Signature someone@example.com was re-sent."
        }
      }

      it 'is aliased as #resend_signature_confirmation' do
        expect(subject).to respond_to(:resend_signature_confirmation).
            with(1).argument
      end

      it 'performs a POST request to /senders/:id/resend endpoint' do
        allow(subject.http_client).to receive(:post).
            with('senders/42/resend').and_return(response)
        subject.resend_sender_confirmation(42)
      end

      it 'formats the keys of returned response' do
        allow(subject.http_client).to receive(:post).and_return(response)
        keys = subject.resend_sender_confirmation(42).keys
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end

    end

    describe '#verified_sender_spf?' do

      let(:response) { {"SPFVerified" => true} }
      let(:false_response) { {"SPFVerified" => false} }

      it 'is aliased as #verified_signature_spf?' do
        expect(subject).to respond_to(:verified_signature_spf?).with(1).argument
      end

      it 'performs a POST request to /senders/:id/verifyspf endpoint' do
        allow(subject.http_client).to receive(:post).
            with('senders/42/verifyspf').and_return(response)
        subject.verified_sender_spf?(42)
      end

      it 'returns false when SPFVerified field of the response is false' do
        allow(subject.http_client).to receive(:post).and_return(false_response)
        expect(subject.verified_sender_spf?(42)).to be_false
      end

      it 'returns true when SPFVerified field of the response is true' do
        allow(subject.http_client).to receive(:post).and_return(response)
        expect(subject.verified_sender_spf?(42)).to be_true
      end

    end

    describe '#request_new_sender_dkim' do

      let(:response) {
        {
          "Domain" => "example.com",
          "EmailAddress" => "someone@example.com",
          "ReplyToEmailAddress" => "info@example.com",
          "Name" => "Example User",
          "Confirmed" => true,
          "ID" => 8139
        }
      }

      it 'is aliased as #request_new_signature_dkim' do
        expect(subject).to respond_to(:request_new_signature_dkim).
            with(1).argument
      end

      it 'performs a POST request to /senders/:id/requestnewdkim endpoint' do
        allow(subject.http_client).to receive(:post).
            with('senders/42/requestnewdkim').and_return(response)
        subject.request_new_sender_dkim(42)
      end

      it 'formats the keys of returned response' do
        allow(subject.http_client).to receive(:post).and_return(response)
        keys = subject.request_new_sender_dkim(42).keys
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end

    end

    describe '#delete_sender' do

      let(:response) {
        {
          "ErrorCode" => 0,
          "Message" => "Signature someone@example.com removed."
        }
      }

      it 'is aliased as #delete_signature' do
        expect(subject).to respond_to(:delete_signature).with(1).argument
      end

      it 'performs a DELETE request to /senders/:id endpoint' do
        allow(subject.http_client).to receive(:delete).
            with('senders/42').and_return(response)
        subject.delete_sender(42)
      end

      it 'formats the keys of returned response' do
        allow(subject.http_client).to receive(:delete).and_return(response)
        keys = subject.delete_sender(42).keys
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end

    end
    
    describe '#domains' do

      let(:response) {
        {
          'TotalCount' => 10, 'Domains' => [{}, {}]
        }
      }

      it 'returns an enumerator' do
        expect(subject.domains).to be_kind_of(Enumerable)
      end

      it 'lazily loads domains' do
        allow(subject.http_client).to receive(:get).
            with('domains', an_instance_of(Hash)).and_return(response)
        subject.domains.take(1000)
      end

    end

    describe '#get_domains' do

      let(:response) {
        {
          "TotalCount" => 1,
          "Domains" => [{
            "Name" => "example.com",
            "ID" => 8139
          }]
        }
      }

      it 'performs a GET request to /domains endpoint' do
        allow(subject.http_client).to receive(:get).
            with('domains', :offset => 0, :count => 30).
            and_return(response)
        subject.get_domains
      end

      it 'formats the keys of returned list of domains' do
        allow(subject.http_client).to receive(:get).and_return(response)
        keys = subject.get_domains.map { |s| s.keys }.flatten
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end

      it 'accepts offset and count options' do
        allow(subject.http_client).to receive(:get).
            with('domains', :offset => 10, :count => 42).
            and_return(response)
        subject.get_domains(:offset => 10, :count => 42)
      end

    end

    describe '#get_domains_count' do

      let(:response) { {'TotalCount' => 42} }

      it 'returns a total number of domains' do
        allow(subject.http_client).to receive(:get).
            with('domains', an_instance_of(Hash)).and_return(response)
        expect(subject.get_domains_count).to eq(42)
      end

    end

    describe '#get_domain' do

      let(:response) {
        {
          "Name" => "example.com",
          "ID" => 8139
        }
      }

      it 'performs a GET request to /domains/:id endpoint' do
        allow(subject.http_client).to receive(:get).with("domains/42").
                                                    and_return(response)
        subject.get_domain(42)
      end

      it 'formats the keys of returned response' do
        allow(subject.http_client).to receive(:get).and_return(response)
        keys = subject.get_domain(42).keys
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end
    end

    describe '#create_domain' do

      let(:response) {
        {
          "Name" => "example.com",
          "ID" => 8139
        }
      }

      it 'performs a POST request to /domains endpoint' do
        allow(subject.http_client).to receive(:post).
            with("domains", an_instance_of(String)).and_return(response)
        subject.create_domain(:name => 'example.com')
      end

      it 'converts the domain attributes names to camel case' do
        allow(subject.http_client).to receive(:post).
            with("domains", {'FooBar' => 'bar'}.to_json).and_return(response)
        subject.create_domain(:foo_bar => 'bar')
      end

      it 'formats the keys of returned response' do
        allow(subject.http_client).to receive(:post).and_return(response)
        keys = subject.create_domain(:foo => 'bar').keys
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end
    end

    describe '#update_domain' do

      let(:response) {
        {
          "Name" => "example.com",
          "ReturnPathDomain" => "return.example.com",
          "ID" => 8139
        }
      }

      it 'performs a PUT request to /domains/:id endpoint' do
        allow(subject.http_client).to receive(:put).
            with('domains/42', an_instance_of(String)).and_return(response)
        subject.update_domain(42, :return_path_domain => 'updated-return.example.com')
      end

      it 'converts the domain attributes names to camel case' do
        allow(subject.http_client).to receive(:put).
            with('domains/42', {'FooBar' => 'bar'}.to_json).and_return(response)
        subject.update_domain(42, :foo_bar => 'bar')
      end

      it 'formats the keys of returned response' do
        allow(subject.http_client).to receive(:put).and_return(response)
        keys = subject.update_domain(42, :foo => 'bar').keys
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end

    end

    describe '#verified_domain_spf?' do

      let(:response) { {"SPFVerified" => true} }
      let(:false_response) { {"SPFVerified" => false} }

      it 'performs a POST request to /domains/:id/verifyspf endpoint' do
        allow(subject.http_client).to receive(:post).
            with('domains/42/verifyspf').and_return(response)
        subject.verified_domain_spf?(42)
      end

      it 'returns false when SPFVerified field of the response is false' do
        allow(subject.http_client).to receive(:post).and_return(false_response)
        expect(subject.verified_domain_spf?(42)).to be_false
      end

      it 'returns true when SPFVerified field of the response is true' do
        allow(subject.http_client).to receive(:post).and_return(response)
        expect(subject.verified_domain_spf?(42)).to be_true
      end

    end

    describe '#rotate_domain_dkim' do

      let(:response) {
        {
          "Name" => "example.com",
          "ID" => 8139
        }
      }

      it 'performs a POST request to /domains/:id/rotatedkim endpoint' do
        allow(subject.http_client).to receive(:post).
            with('domains/42/rotatedkim').and_return(response)
        subject.rotate_domain_dkim(42)
      end

      it 'formats the keys of returned response' do
        allow(subject.http_client).to receive(:post).and_return(response)
        keys = subject.rotate_domain_dkim(42).keys
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end

    end

    describe '#delete_domain' do

      let(:response) {
        {
          "ErrorCode" => 0,
          "Message" => "Domain example.com removed."
        }
      }

      it 'performs a DELETE request to /domains/:id endpoint' do
        allow(subject.http_client).to receive(:delete).
            with('domains/42').and_return(response)
        subject.delete_domain(42)
      end

      it 'formats the keys of returned response' do
        allow(subject.http_client).to receive(:delete).and_return(response)
        keys = subject.delete_sender(42).keys
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end

    end

    describe '#servers' do

      let(:response) { {'TotalCount' => 10, 'Servers' => [{}, {}]} }

      it 'returns an enumerator' do
        expect(subject.servers).to be_kind_of(Enumerable)
      end

      it 'lazily loads servers' do
        allow(subject.http_client).to receive(:get).
            with('servers', an_instance_of(Hash)).and_return(response)
        subject.servers.take(100)
      end

    end

    describe '#get_servers' do

      let(:response) {
        {
          'TotalCount' => 1,
          'Servers' => [
            {
              "ID" => 11635,
              "Name" => "Production01",
              "ApiTokens" => [
                "fe6ec0cf-ff06-787a-b5e9-e77a41c61ce3"
              ],
              "ServerLink" => "https://postmarkapp.com/servers/11635/overview",
              "Color" => "red",
              "SmtpApiActivated" => true,
              "RawEmailEnabled" => false,
              "InboundAddress" => "7373de3ebd66acea228fjkdkf88dd7d5@inbound.postmarkapp.com",
              "InboundHookUrl" => "http://inboundhook.example.com/inbound",
              "BounceHookUrl" => "http://bouncehook.example.com/bounce",
              "InboundDomain" => "",
              "InboundHash" => "7373de3ebd66acea228fjkdkf88dd7d5"
            }
          ]
        }
      }

      it 'performs a GET request to /servers endpoint' do
        allow(subject.http_client).to receive(:get).
            with('servers', an_instance_of(Hash)).and_return(response)
        subject.get_servers
      end

      it 'formats the keys of returned list of servers' do
        allow(subject.http_client).to receive(:get).and_return(response)
        keys = subject.get_servers.map { |s| s.keys }.flatten
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end

      it 'accepts offset and count options' do
        allow(subject.http_client).to receive(:get).
            with('servers', :offset => 30, :count => 50).
            and_return(response)
        subject.get_servers(:offset => 30, :count => 50)
      end
    end

    describe '#get_server' do

      let(:response) {
        {
          "ID" => 7438,
          "Name" => "Staging Testing",
          "ApiTokens" => [
            "fe6ec0cf-ff06-44aa-jf88-e77a41c61ce3"
          ],
          "ServerLink" => "https://postmarkapp.com/servers/7438/overview",
          "Color" => "red",
          "SmtpApiActivated" => true,
          "RawEmailEnabled" => false,
          "InboundAddress" => "7373de3ebd66acea22812731fb1dd7d5@inbound.postmarkapp.com",
          "InboundHookUrl" => "",
          "BounceHookUrl" => "",
          "InboundDomain" => "",
          "InboundHash" => "7373de3ebd66acea22812731fb1dd7d5"
        }
      }

      it 'performs a GET request to /servers/:id endpoint' do
        allow(subject.http_client).to receive(:get).
            with('servers/42').and_return(response)
        subject.get_server(42)
      end

      it 'formats the keys of returned response' do
        allow(subject.http_client).to receive(:get).and_return(response)
        keys = subject.get_server(42).keys
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end

    end

    describe '#get_servers_count' do

      let(:response) { {'TotalCount' => 42} }

      it 'returns a total number of servers' do
        allow(subject.http_client).to receive(:get).
            with('servers', an_instance_of(Hash)).and_return(response)
        expect(subject.get_servers_count).to eq(42)
      end

    end

    describe '#create_server' do

      let(:response) {
        {
          "Name" => "Staging Testing",
          "Color" => "red",
          "SmtpApiActivated" => true,
          "RawEmailEnabled" => false,
          "InboundHookUrl" => "http://hooks.example.com/inbound",
          "BounceHookUrl" => "http://hooks.example.com/bounce",
          "InboundDomain" => ""
        }
      }

      it 'performs a POST request to /servers endpoint' do
        allow(subject.http_client).to receive(:post).
            with('servers', an_instance_of(String)).and_return(response)
        subject.create_server(:foo => 'bar')
      end

      it 'converts the server attribute names to camel case' do
        allow(subject.http_client).to receive(:post).
            with('servers', {'FooBar' => 'foo_bar'}.to_json).
            and_return(response)
        subject.create_server(:foo_bar => 'foo_bar')
      end

      it 'formats the keys of returned response' do
        allow(subject.http_client).to receive(:post).and_return(response)
        keys = subject.create_server(:foo => 'bar').keys
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end

    end

    describe '#update_server' do
      let(:response) {
        {
          "ID" => 7450,
          "Name" => "Production Testing",
          "ApiTokens" => [
              "fe6ec0cf-ff06-44aa-jf88-e77a41c61ce3"
          ],
          "ServerLink" => "https://postmarkapp.com/servers/7438/overview",
          "Color" => "blue",
          "SmtpApiActivated" => false,
          "RawEmailEnabled" => false,
          "InboundAddress" => "7373de3ebd66acea22812731fb1dd7d5@inbound.postmarkapp.com",
          "InboundHookUrl" => "http://hooks.example.com/inbound",
          "BounceHookUrl" => "http://hooks.example.com/bounce",
          "InboundDomain" => "",
          "InboundHash" => "7373de3ebd66acea22812731fb1dd7d5"
        }
      }

      it 'converts the server attribute names to camel case' do
        allow(subject.http_client).to receive(:put).
            with(an_instance_of(String), {'FooBar' => 'foo_bar'}.to_json).
            and_return(response)
        subject.update_server(42, :foo_bar => 'foo_bar')
      end

      it 'performs a PUT request to /servers/:id endpoint' do
        allow(subject.http_client).to receive(:put).
            with('servers/42', an_instance_of(String)).
            and_return(response)
        subject.update_server(42, :foo => 'bar')
      end

      it 'formats the keys of returned response' do
        allow(subject.http_client).to receive(:put).and_return(response)
        keys = subject.update_server(42, :foo => 'bar').keys
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end

    end

    describe '#delete_server' do

      let(:response) {
        {
          "ErrorCode" => "0",
          "Message" => "Server Production Testing removed."
        }
      }

      it 'performs a DELETE request to /servers/:id endpoint' do
        allow(subject.http_client).to receive(:delete).
            with('servers/42').and_return(response)
        subject.delete_server(42)
      end

      it 'formats the keys of returned response' do
        allow(subject.http_client).to receive(:delete).and_return(response)
        keys = subject.delete_server(42).keys
        expect(keys.all? { |k| k.is_a?(Symbol) }).to be_true
      end

    end

  end

end
