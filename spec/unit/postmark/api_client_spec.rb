require 'spec_helper'

describe Postmark::ApiClient do
  let(:api_client) {Postmark::ApiClient.new(api_token)}
  let(:api_token) {"provided-api-token"}
  let(:message_hash) {{:from => "support@postmarkapp.com"}}
  let(:message) do
    Mail.new do
      from "support@postmarkapp.com"
      delivery_method Mail::Postmark
    end
  end
  let(:templated_message) do
    Mail.new do
      from            "sheldon@bigbangtheory.com"
      to              "lenard@bigbangtheory.com"
      template_alias  "hello"
      template_model  :name => "Sheldon"
    end
  end
  let(:http_client) {api_client.http_client}

  shared_examples "retryable" do |response|
    let(:api_client) do
      Postmark::ApiClient.new(
        api_token,
        max_retries.nil? ? {} : {:max_retries => max_retries}
      )
    end
    let(:max_retries) {nil}

    context 'with no retries' do
      let(:max_retries) {nil}

      it "doesn't retry failed requests" do
        expect(http_client).to receive(:post).once.and_raise(Postmark::InternalServerError)
        expect {subject}.to raise_error(Postmark::InternalServerError)
      end
    end

    context 'with 3 retries' do
      let(:max_retries) {3}

      it 'retries 3 times' do
        expect(http_client).to receive(:post).twice.and_raise(Postmark::InternalServerError)
        expect(http_client).to receive(:post).and_return(response)
        expect {subject}.not_to raise_error
      end

      it 'gives up after 3 retries' do
        expect(http_client).to receive(:post).thrice.and_raise(Postmark::InternalServerError)
        expect {subject}.to raise_error(Postmark::InternalServerError)
      end

      it "retries on timeout" do
        expect(http_client).to receive(:post).and_raise(Postmark::TimeoutError)
        expect(http_client).to receive(:post).and_return(response)
        expect {subject}.not_to raise_error
      end
    end
  end

  describe "attr readers" do
    it { expect(api_client).to respond_to(:http_client) }
    it { expect(api_client).to respond_to(:max_retries) }
  end

  context "when it's created without options" do
    let(:api_client) {Postmark::ApiClient.new(api_token)}

    specify { expect(api_client.max_retries).to eq 0 }
  end

  context "when it's created with user options" do
    let(:api_client) {Postmark::ApiClient.new(api_token, options)}
    let(:options) { {:max_retries => 42, :foo => :bar} }

    it "sets max_retries" do
      expect(api_client.max_retries).to eq 42
    end

    it 'passes other options to HttpClient instance' do
      expect(Postmark::HttpClient).to receive(:new).with(api_token, :foo => :bar)
      api_client
    end
  end

  describe "#api_token=" do
    let(:api_token) {"new-api-token-value"}

    it 'assigns the api token to the http client instance' do
      api_client.api_token = api_token
      expect(api_client.http_client.api_token).to eq api_token
    end

    it 'is aliased as api_key=' do
      api_client.api_key = api_token
      expect(api_client.http_client.api_token).to eq api_token
    end
  end

  describe "#deliver" do
    subject {api_client.deliver(message_hash)}

    let(:email) {Postmark::MessageHelper.to_postmark(message_hash)}
    let(:email_json) {Postmark::Json.encode(email)}
    let(:response) {{"MessageID" => 42}}

    it 'converts message hash to Postmark format and posts it to expected enpoint' do
      expect(http_client).to receive(:post).with('email', email_json) {response}
      subject
    end

    it 'converts response to ruby format' do
      expect(http_client).to receive(:post).with('email', email_json) {response}
      expect(subject).to have_key(:message_id)
    end

    it_should_behave_like "retryable"
  end

  describe "#deliver_in_batches" do
    subject {api_client.deliver_in_batches([message_hash, message_hash, message_hash])}

    let(:email) {Postmark::MessageHelper.to_postmark(message_hash)}
    let(:emails) {[email, email, email]}
    let(:emails_json) {Postmark::Json.encode(emails)}
    let(:response) {[{'ErrorCode' => 0}, {'ErrorCode' => 0}, {'ErrorCode' => 0}]}

    it 'turns array of messages into a JSON document and posts it to expected endpoint' do
      expect(http_client).to receive(:post).with('email/batch', emails_json) {response}
      subject
    end

    it 'converts response to ruby format' do
      expect(http_client).to receive(:post).with('email/batch', emails_json) {response}
      response = subject
      expect(response.first).to have_key(:error_code)
    end

    it_should_behave_like "retryable"
  end

  describe "#deliver_message" do
    subject {api_client.deliver_message(message)}

    let(:email) {message.to_postmark_hash}
    let(:email_json) {Postmark::Json.encode(email)}

    context 'when given a templated message' do
      let(:message) {templated_message}

      specify do
        expect { subject }.to raise_error(ArgumentError, /Please use Postmark::ApiClient\#deliver_message_with_template/)
      end
    end

    it 'turns message into a JSON document and posts it to /email' do
      expect(http_client).to receive(:post).with('email', email_json)
      subject
    end

    it "proxies errors" do
      allow(http_client).to receive(:post).and_raise(Postmark::TimeoutError)
      expect {subject}.to raise_error(Postmark::TimeoutError)
    end

    it_should_behave_like "retryable"
  end

  describe "#deliver_message_with_template" do
    subject {api_client.deliver_message_with_template(templated_message)}

    let(:email) {templated_message.to_postmark_hash}
    let(:email_json) {Postmark::Json.encode(email)}

    context 'when given a non-templated message' do
      let(:templated_message) {message}

      specify do
        expect { subject }.to raise_error(ArgumentError, 'Templated delivery requested, but the template is missing.')
      end
    end

    it 'turns message into a JSON document and posts it to expected endpoint' do
      expect(http_client).to receive(:post).with('email/withTemplate', email_json)
      subject
    end

    it "proxies errors" do
      allow(http_client).to receive(:post).and_raise(Postmark::TimeoutError)
      expect {subject}.to raise_error(Postmark::TimeoutError)
    end

    it_should_behave_like "retryable"
  end

  describe "#deliver_messages" do
    subject {api_client.deliver_messages(messages)}

    let(:messages) {[message, message, message]}
    let(:email) {message.to_postmark_hash}
    let(:emails_json) {Postmark::Json.encode(Array.new(3) { email })}
    let(:response) {[{}, {}, {}]}

    context 'when given templated messages' do
      let(:messages) {[templated_message]}

      specify do
        expect { subject }.to raise_error(ArgumentError, /Please use Postmark::ApiClient\#deliver_messages_with_templates/)
      end
    end

    it 'turns array of messages into a JSON document and posts it to /email/batch' do
      expect(http_client).to receive(:post).with('email/batch', emails_json) {response}
      subject
    end

    it_should_behave_like 'retryable', []
  end

  describe "#deliver_messages_with_templates" do
    subject {api_client.deliver_messages_with_templates(messages)}

    let(:email) {templated_message.to_postmark_hash}
    let(:emails_json) {Postmark::Json.encode(:Messages => Array.new(3) { email })}
    let(:response) {[{}, {}, {}]}
    let(:messages) { Array.new(3) { templated_message } }

    context 'when given a non-templated message' do
      let(:messages) {[message]}

      it 'raises an error ' do
        expect { subject }.
          to raise_error(ArgumentError, 'Templated delivery requested, but one or more messages lack templates.')
      end
    end

    it 'turns array of messages into a JSON document and posts it to expected endpoint' do
      expect(http_client).to receive(:post).with('email/batchWithTemplates', emails_json) {response}
      subject
    end

    it_should_behave_like 'retryable', []
  end

  describe "#delivery_stats" do
    let(:response) {{"Bounces" => [{"Foo" => "Bar"}]}}

    it 'requests data at /deliverystats' do
      expect(http_client).to receive(:get).with("deliverystats") {response}
      expect(api_client.delivery_stats).to have_key(:bounces)
    end
  end

  describe '#messages' do
    context 'given outbound' do
      let(:response) {{'TotalCount' => 5, 'Messages' => [{}].cycle(5).to_a}}

      it 'returns an enumerator' do
        expect(api_client.messages).to be_kind_of(Enumerable)
      end

      it 'loads outbound messages' do
        allow(api_client.http_client).to receive(:get).
            with('messages/outbound', an_instance_of(Hash)).and_return(response)
        expect(api_client.messages.count).to eq(5)
      end
    end

    context 'given inbound' do
      let(:response) {{'TotalCount' => 5, 'InboundMessages' => [{}].cycle(5).to_a}}

      it 'returns an enumerator' do
        expect(api_client.messages(:inbound => true)).to be_kind_of(Enumerable)
      end

      it 'loads inbound messages' do
        allow(api_client.http_client).to receive(:get).with('messages/inbound', an_instance_of(Hash)).and_return(response)
        expect(api_client.messages(:inbound => true).count).to eq(5)
      end
    end
  end

  describe '#get_messages' do
    context 'given outbound' do
      let(:response) {{"TotalCount" => 1, "Messages" => [{}]}}

      it 'requests data at /messages/outbound' do
        expect(http_client).to receive(:get).
            with('messages/outbound', :offset => 50, :count => 50).
            and_return(response)
        api_client.get_messages(:offset => 50, :count => 50)
      end
    end

    context 'given inbound' do
      let(:response) {{"TotalCount" => 1, "InboundMessages" => [{}]}}

      it 'requests data at /messages/inbound' do
        expect(http_client).to receive(:get).with('messages/inbound', :offset => 50, :count => 50).and_return(response)
        expect(api_client.get_messages(:inbound => true, :offset => 50, :count => 50)).to be_an(Array)
      end
    end
  end

  describe '#get_messages_count' do
    let(:response) {{'TotalCount' => 42}}

    context 'given outbound' do

      it 'requests and returns outbound messages count' do
        allow(api_client.http_client).to receive(:get).
            with('messages/outbound', an_instance_of(Hash)).and_return(response)
        expect(api_client.get_messages_count).to eq(42)
        expect(api_client.get_messages_count(:inbound => false)).to eq(42)
      end

    end

    context 'given inbound' do
      it 'requests and returns inbound messages count' do
        allow(api_client.http_client).to receive(:get).
            with('messages/inbound', an_instance_of(Hash)).and_return(response)
        expect(api_client.get_messages_count(:inbound => true)).to eq(42)
      end
    end

  end

  describe '#get_message' do
    let(:id) {'8ad0e8b0-xxxx-xxxx-951d-223c581bb467'}
    let(:response) {{"To" => "leonard@bigbangtheory.com"}}

    context 'given outbound' do
      it 'requests a single message by id at /messages/outbound/:id/details' do
        expect(http_client).to receive(:get).
            with("messages/outbound/#{id}/details", {}).
            and_return(response)
        expect(api_client.get_message(id)).to have_key(:to)
      end
    end

    context 'given inbound' do
      it 'requests a single message by id at /messages/inbound/:id/details' do
        expect(http_client).to receive(:get).
            with("messages/inbound/#{id}/details", {}).
            and_return(response)
        expect(api_client.get_message(id, :inbound => true)).to have_key(:to)
      end
    end
  end

  describe '#dump_message' do
    let(:id) {'8ad0e8b0-xxxx-xxxx-951d-223c581bb467'}
    let(:response) {{"Body" => "From: <leonard@bigbangtheory.com> \r\n ..."}}

    context 'given outbound' do

      it 'requests a single message by id at /messages/outbound/:id/dump' do
        expect(http_client).to receive(:get).
            with("messages/outbound/#{id}/dump", {}).
            and_return(response)
        expect(api_client.dump_message(id)).to have_key(:body)
      end

    end

    context 'given inbound' do
      it 'requests a single message by id at /messages/inbound/:id/dump' do
        expect(http_client).to receive(:get).
            with("messages/inbound/#{id}/dump", {}).
            and_return(response)
        expect(api_client.dump_message(id, :inbound => true)).to have_key(:body)
      end
    end
  end

  describe '#bounces' do
    it 'returns an Enumerator' do
      expect(api_client.bounces).to be_kind_of(Enumerable)
    end

    it 'requests data at /bounces' do
      allow(api_client.http_client).to receive(:get).
          with('bounces', an_instance_of(Hash)).
          and_return('TotalCount' => 1, 'Bounces' => [{}])
      expect(api_client.bounces.first(5).count).to eq(1)
    end
  end

  describe "#get_bounces" do
    let(:options) {{:foo => :bar}}
    let(:response) {{"Bounces" => []}}

    it 'requests data at /bounces' do
      allow(http_client).to receive(:get).with("bounces", options) {response}
      expect(api_client.get_bounces(options)).to be_an(Array)
      expect(api_client.get_bounces(options).count).to be_zero
    end
  end

  describe "#get_bounce" do
    let(:id) {42}

    it 'requests a single bounce by ID at /bounces/:id' do
      expect(http_client).to receive(:get).with("bounces/#{id}")
      api_client.get_bounce(id)
    end
  end

  describe "#dump_bounce" do
    let(:id) {42}

    it 'requests a specific bounce data at /bounces/:id/dump' do
      expect(http_client).to receive(:get).with("bounces/#{id}/dump")
      api_client.dump_bounce(id)
    end
  end

  describe "#activate_bounce" do
    let(:id) {42}
    let(:response) {{"Bounce" => {}}}

    it 'activates a specific bounce by sending a PUT request to /bounces/:id/activate' do
      expect(http_client).to receive(:put).with("bounces/#{id}/activate") {response}
      api_client.activate_bounce(id)
    end
  end

  describe '#opens' do
    it 'returns an Enumerator' do
      expect(api_client.opens).to be_kind_of(Enumerable)
    end

    it 'performs a GET request to /opens/tags' do
      allow(api_client.http_client).to receive(:get).
          with('messages/outbound/opens', an_instance_of(Hash)).
          and_return('TotalCount' => 1, 'Opens' => [{}])
      expect(api_client.opens.first(5).count).to eq(1)
    end
  end

  describe '#clicks' do
    it 'returns an Enumerator' do
      expect(api_client.clicks).to be_kind_of(Enumerable)
    end

    it 'performs a GET request to /clicks/tags' do
      allow(api_client.http_client).to receive(:get).
          with('messages/outbound/clicks', an_instance_of(Hash)).
          and_return('TotalCount' => 1, 'Clicks' => [{}])
      expect(api_client.clicks.first(5).count).to eq(1)
    end
  end

  describe '#get_opens' do
    let(:options) {{:offset => 5}}
    let(:response) {{'Opens' => [], 'TotalCount' => 0}}

    it 'performs a GET request to /messages/outbound/opens' do
      allow(http_client).to receive(:get).with('messages/outbound/opens', options) {response}
      expect(api_client.get_opens(options)).to be_an(Array)
      expect(api_client.get_opens(options).count).to be_zero
    end
  end

  describe '#get_clicks' do
    let(:options) {{:offset => 5}}
    let(:response) {{'Clicks' => [], 'TotalCount' => 0}}

    it 'performs a GET request to /messages/outbound/clicks' do
      allow(http_client).to receive(:get).with('messages/outbound/clicks', options) {response}
      expect(api_client.get_clicks(options)).to be_an(Array)
      expect(api_client.get_clicks(options).count).to be_zero
    end
  end

  describe '#get_opens_by_message_id' do
    let(:message_id) {42}
    let(:options) {{:offset => 5}}
    let(:response) {{'Opens' => [], 'TotalCount' => 0}}

    it 'performs a GET request to /messages/outbound/opens' do
      allow(http_client).to receive(:get).with("messages/outbound/opens/#{message_id}", options).and_return(response)
      expect(api_client.get_opens_by_message_id(message_id, options)).to be_an(Array)
      expect(api_client.get_opens_by_message_id(message_id, options).count).to be_zero
    end
  end

  describe '#get_clicks_by_message_id' do
    let(:message_id) {42}
    let(:options) {{:offset => 5}}
    let(:response) {{'Clicks' => [], 'TotalCount' => 0}}

    it 'performs a GET request to /messages/outbound/clicks' do
      allow(http_client).to receive(:get).with("messages/outbound/clicks/#{message_id}", options).and_return(response)
      expect(api_client.get_clicks_by_message_id(message_id, options)).to be_an(Array)
      expect(api_client.get_clicks_by_message_id(message_id, options).count).to be_zero
    end
  end

  describe '#opens_by_message_id' do
    let(:message_id) {42}

    it 'returns an Enumerator' do
      expect(api_client.opens_by_message_id(message_id)).to be_kind_of(Enumerable)
    end

    it 'performs a GET request to /opens/tags' do
      allow(api_client.http_client).to receive(:get).
          with("messages/outbound/opens/#{message_id}", an_instance_of(Hash)).
          and_return('TotalCount' => 1, 'Opens' => [{}])
      expect(api_client.opens_by_message_id(message_id).first(5).count).to eq(1)
    end
  end

  describe '#clicks_by_message_id' do
    let(:message_id) {42}

    it 'returns an Enumerator' do
      expect(api_client.clicks_by_message_id(message_id)).to be_kind_of(Enumerable)
    end

    it 'performs a GET request to /clicks/tags' do
      allow(api_client.http_client).to receive(:get).
          with("messages/outbound/clicks/#{message_id}", an_instance_of(Hash)).
          and_return('TotalCount' => 1, 'Clicks' => [{}])
      expect(api_client.clicks_by_message_id(message_id).first(5).count).to eq(1)
    end
  end

  describe '#create_trigger' do
    context 'inbound rules' do
      let(:options) {{:rule => 'example.com'}}
      let(:response) {{'Rule' => 'example.com'}}

      it 'performs a POST request to /triggers/inboundrules with given options' do
        allow(http_client).to receive(:post).with('triggers/inboundrules',
                                                  {'Rule' => 'example.com'}.to_json)
        api_client.create_trigger(:inbound_rules, options)
      end

      it 'symbolizes response keys' do
        allow(http_client).to receive(:post).and_return(response)
        expect(api_client.create_trigger(:inbound_rules, options)).to eq(:rule => 'example.com')
      end
    end
  end

  describe '#get_trigger' do
    let(:id) {42}

    it 'performs a GET request to /triggers/tags/:id' do
      allow(http_client).to receive(:get).with("triggers/tags/#{id}")
      api_client.get_trigger(:tags, id)
    end

    it 'symbolizes response keys' do
      allow(http_client).to receive(:get).and_return('Foo' => 'Bar')
      expect(api_client.get_trigger(:tags, id)).to eq(:foo => 'Bar')
    end
  end

  describe '#delete_trigger' do
    context 'tags' do
      let(:id) {42}

      it 'performs a DELETE request to /triggers/tags/:id' do
        allow(http_client).to receive(:delete).with("triggers/tags/#{id}")
        api_client.delete_trigger(:tags, id)
      end

      it 'symbolizes response keys' do
        allow(http_client).to receive(:delete).and_return('Foo' => 'Bar')
        expect(api_client.delete_trigger(:tags, id)).to eq(:foo => 'Bar')
      end
    end

    context 'inbound rules' do
      let(:id) {42}

      it 'performs a DELETE request to /triggers/inboundrules/:id' do
        allow(http_client).to receive(:delete).with("triggers/inboundrules/#{id}")
        api_client.delete_trigger(:inbound_rules, id)
      end

      it 'symbolizes response keys' do
        allow(http_client).to receive(:delete).and_return('Rule' => 'example.com')
        expect(api_client.delete_trigger(:tags, id)).to eq(:rule => 'example.com')
      end
    end
  end

  describe '#get_triggers' do
    let(:options) {{:offset => 5}}

    context 'inbound rules' do
      let(:response) {{'InboundRules' => [], 'TotalCount' => 0}}

      it 'performs a GET request to /triggers/inboundrules' do
        allow(http_client).to receive(:get).with('triggers/inboundrules', options) {response}
        expect(api_client.get_triggers(:inbound_rules, options)).to be_an(Array)
        expect(api_client.get_triggers(:inbound_rules, options).count).to be_zero
      end
    end
  end

  describe '#triggers' do
    it 'returns an Enumerator' do
      expect(api_client.triggers(:tags)).to be_kind_of(Enumerable)
    end

    it 'performs a GET request to /triggers/tags' do
      allow(api_client.http_client).to receive(:get).
          with('triggers/tags', an_instance_of(Hash)).
          and_return('TotalCount' => 1, 'Tags' => [{}])
      expect(api_client.triggers(:tags).first(5).count).to eq(1)
    end
  end

  describe "#server_info" do
    let(:response) {
      {
        "Name" => "Testing",
        "Color" => "blue",
        "InboundHash" => "c2425d77f74f8643e5f6237438086c81",
        "SmtpApiActivated" => true
      }
    }

    it 'requests server info from Postmark and converts it to ruby format' do
      expect(http_client).to receive(:get).with('server') {response}
      expect(api_client.server_info).to have_key(:inbound_hash)
    end
  end

  describe "#update_server_info" do
    let(:response) {
      {
        "Name" => "Testing",
        "Color" => "blue",
        "InboundHash" => "c2425d77f74f8643e5f6237438086c81",
        "SmtpApiActivated" => false
      }
    }
    let(:update) {{:smtp_api_activated => false}}

    it 'updates server info in Postmark and converts it to ruby format' do
      expect(http_client).to receive(:put).with('server', anything) {response}
      expect(api_client.update_server_info(update)[:smtp_api_activated]).to be false
    end
  end

  describe '#get_templates' do
    let(:response) do
      {
          'TotalCount' => 31,
          'Templates' => [
              {
                  'Active' => true,
                  'TemplateId' => 123,
                  'Name' => 'ABC'
              },
              {
                  'Active' => true,
                  'TemplateId' => 456,
                  'Name' => 'DEF'
              }
          ]
      }
    end

    it 'gets templates info and converts it to ruby format' do
      expect(http_client).to receive(:get).with('templates', :offset => 0, :count => 2).and_return(response)

      count, templates = api_client.get_templates(:count => 2)

      expect(count).to eq(31)
      expect(templates.first[:template_id]).to eq(123)
      expect(templates.first[:name]).to eq('ABC')
    end
  end

  describe '#templates' do
    it 'returns an Enumerator' do
      expect(api_client.templates).to be_kind_of(Enumerable)
    end

    it 'requests data at /templates' do
      allow(api_client.http_client).to receive(:get).
          with('templates', an_instance_of(Hash)).
          and_return('TotalCount' => 1, 'Templates' => [{}])
      expect(api_client.templates.first(5).count).to eq(1)
    end
  end

  describe '#get_template' do
    let(:response) do
      {
          'Name' => 'Template Name',
          'TemplateId' => 123,
          'Subject' => 'Subject',
          'HtmlBody' => 'Html',
          'TextBody' => 'Text',
          'AssociatedServerId' => 456,
          'Active' => true
      }
    end

    it 'gets single template and converts it to ruby format' do
      expect(http_client).to receive(:get).with('templates/123').and_return(response)

      template = api_client.get_template('123')

      expect(template[:name]).to eq('Template Name')
      expect(template[:template_id]).to eq(123)
      expect(template[:html_body]).to eq('Html')
    end
  end

  describe '#create_template' do
    let(:response) do
      {
          'TemplateId' => 123,
          'Name' => 'template name',
          'Active' => true
      }
    end

    it 'performs a POST request to /templates with the given attributes' do
      expect(http_client).to receive(:post).
        with('templates', json_representation_of('Name' => 'template name')).
        and_return(response)

      template = api_client.create_template(:name => 'template name')

      expect(template[:name]).to eq('template name')
      expect(template[:template_id]).to eq(123)
    end
  end

  describe '#update_template' do
    let(:response) do
      {
          'TemplateId' => 123,
          'Name' => 'template name',
          'Active' => true
      }
    end

    it 'performs a PUT request to /templates with the given attributes' do
      expect(http_client).to receive(:put).
        with('templates/123', json_representation_of('Name' => 'template name')).
        and_return(response)

      template = api_client.update_template(123, :name => 'template name')

      expect(template[:name]).to eq('template name')
      expect(template[:template_id]).to eq(123)
    end
  end

  describe '#delete_template' do
    let(:response) do
      {
          'ErrorCode' => 0,
          'Message' => 'Template 123 removed.'
      }
    end

    it 'performs a DELETE request to /templates/:id' do
      expect(http_client).to receive(:delete).with('templates/123').and_return(response)

      resp = api_client.delete_template(123)

      expect(resp[:error_code]).to eq(0)
    end
  end

  describe '#validate_template' do
    context 'when template is valid' do
      let(:response) do
        {
            'AllContentIsValid' => true,
            'HtmlBody' => {
                'ContentIsValid' => true,
                'ValidationErrors' => [],
                'RenderedContent' => '<html><head></head><body>MyName_Value</body></html>'
            },
            'TextBody' => {
                'ContentIsValid' => true,
                'ValidationErrors' => [],
                'RenderedContent' => 'MyName_Value'
            },
            'Subject' => {
                'ContentIsValid' => true,
                'ValidationErrors' => [],
                'RenderedContent' => 'MyName_Value'
            },
            'SuggestedTemplateModel' => {
                'MyName' => 'MyName_Value'
            }
        }
      end

      it 'performs a POST request and returns unmodified suggested template model' do
        expect(http_client).to receive(:post).
          with('templates/validate',
               json_representation_of('HtmlBody' => '{{MyName}}',
                                      'TextBody' => '{{MyName}}',
                                      'Subject' => '{{MyName}}')).
          and_return(response)

        resp = api_client.validate_template(:html_body => '{{MyName}}',
                                            :text_body => '{{MyName}}',
                                            :subject => '{{MyName}}')

        expect(resp[:all_content_is_valid]).to be true
        expect(resp[:html_body][:content_is_valid]).to be true
        expect(resp[:html_body][:validation_errors]).to be_empty
        expect(resp[:suggested_template_model]['MyName']).to eq('MyName_Value')
      end
    end

    context 'when template is invalid' do
      let(:response) do
        {
            'AllContentIsValid' => false,
            'HtmlBody' => {
                'ContentIsValid' => false,
                'ValidationErrors' => [
                    {
                        'Message' => 'The \'each\' block being opened requires a model path to be specified in the form \'{#each <name>}\'.',
                        'Line' => 1,
                        'CharacterPosition' => 1
                    }
                ],
                'RenderedContent' => nil
            },
            'TextBody' => {
                'ContentIsValid' => true,
                'ValidationErrors' => [],
                'RenderedContent' => 'MyName_Value'
            },
            'Subject' => {
                'ContentIsValid' => true,
                'ValidationErrors' => [],
                'RenderedContent' => 'MyName_Value'
            },
            'SuggestedTemplateModel' => nil
        }
      end

      it 'performs a POST request and returns validation errors' do
        expect(http_client).
          to receive(:post).with('templates/validate',
                                 json_representation_of('HtmlBody' => '{{#each}}',
                                                        'TextBody' => '{{MyName}}',
                                                        'Subject' => '{{MyName}}')).and_return(response)

        resp = api_client.validate_template(:html_body => '{{#each}}',
                                            :text_body => '{{MyName}}',
                                            :subject => '{{MyName}}')

        expect(resp[:all_content_is_valid]).to be false
        expect(resp[:text_body][:content_is_valid]).to be true
        expect(resp[:html_body][:content_is_valid]).to be false
        expect(resp[:html_body][:validation_errors].first[:character_position]).to eq(1)
        expect(resp[:html_body][:validation_errors].first[:message]).to eq('The \'each\' block being opened requires a model path to be specified in the form \'{#each <name>}\'.')
      end
    end
  end

  describe "#deliver_with_template" do
    subject {api_client.deliver_with_template(message_hash)}

    let(:email) {Postmark::MessageHelper.to_postmark(message_hash)}
    let(:response) {{"MessageID" => 42}}

    it 'converts message hash to Postmark format and posts it to /email/withTemplate' do
      expect(http_client).to receive(:post).with('email/withTemplate', json_representation_of(email)) {response}
      subject
    end

    it 'converts response to ruby format' do
      expect(http_client).to receive(:post).with('email/withTemplate', json_representation_of(email)) {response}
      expect(subject).to have_key(:message_id)
    end

    it_should_behave_like "retryable"
  end

  describe '#deliver_in_batches_with_templates' do
    let(:max_batch_size) {50}
    let(:factor) {3.5}
    let(:postmark_response) do
      {
          'ErrorCode' => 0,
          'Message' => 'OK',
          'SubmittedAt' => '2018-03-14T09:56:50.4288265-04:00',
          'To' => 'recipient@example.org'
      }
    end

    let(:message_hashes) do
      Array.new((factor * max_batch_size).to_i) do
        {
            :template_id => 42,
            :alias => 'alias',
            :template_model => {:Foo => 'attr_value'},
            :from => 'sender@example.org',
            :to => 'recipient@example.org'
        }
      end
    end

    before {api_client.max_batch_size = max_batch_size}

    it 'performs a total of (bath_size / max_batch_size) requests' do
      expect(http_client).
          to receive(:post).with('email/batchWithTemplates', a_postmark_json).
              at_most(factor.to_i).times do
        Array.new(max_batch_size) {postmark_response}
      end

      expect(http_client).
          to receive(:post).with('email/batchWithTemplates', a_postmark_json).
              exactly((factor - factor.to_i).ceil).times do
        response = Array.new(((factor - factor.to_i) * max_batch_size).to_i) do
          postmark_response
        end
        response
      end

      response = api_client.deliver_in_batches_with_templates(message_hashes)
      expect(response).to be_an Array
      expect(response.size).to eq message_hashes.size

      response.each do |message_status|
        expect(message_status).to have_key(:error_code)
        expect(message_status).to have_key(:message)
        expect(message_status).to have_key(:to)
        expect(message_status).to have_key(:submitted_at)
      end
    end
  end

  describe '#get_stats_totals' do
    let(:response) do
      {
          "Sent" => 615,
          "BounceRate" => 10.406,
      }
    end

    it 'converts response to ruby format' do
      expect(http_client).to receive(:get).with('stats/outbound', {:tag => 'foo'}) {response}
      response = api_client.get_stats_totals(:tag => 'foo')
      expect(response).to have_key(:sent)
      expect(response).to have_key(:bounce_rate)
    end
  end

  describe '#get_stats_counts' do
    let(:response) do
      {
          "Days" => [
              {
                  "Date" => "2014-01-01",
                  "Sent" => 140
              },
              {
                  "Date" => "2014-01-02",
                  "Sent" => 160
              },
              {
                  "Date" => "2014-01-04",
                  "Sent" => 50
              },
              {
                  "Date" => "2014-01-05",
                  "Sent" => 115
              }
          ],
          "Sent" => 615
      }
    end

    it 'converts response to ruby format' do
      expect(http_client).to receive(:get).with('stats/outbound/sends', {:tag => 'foo'}) {response}
      response = api_client.get_stats_counts(:sends, :tag => 'foo')
      expect(response).to have_key(:days)
      expect(response).to have_key(:sent)

      first_day = response[:days].first
      expect(first_day).to have_key(:date)
      expect(first_day).to have_key(:sent)
    end

    it 'uses fromdate that is passed in' do
      expect(http_client).to receive(:get).with('stats/outbound/sends', {:tag => 'foo', :fromdate => '2015-01-01'}) {response}
      response = api_client.get_stats_counts(:sends, :tag => 'foo', :fromdate => '2015-01-01')
      expect(response).to have_key(:days)
      expect(response).to have_key(:sent)

      first_day = response[:days].first
      expect(first_day).to have_key(:date)
      expect(first_day).to have_key(:sent)
    end

    it 'uses stats type that is passed in' do
      expect(http_client).to receive(:get).with('stats/outbound/opens/readtimes', {:tag => 'foo', :type => :readtimes}) {response}
      response = api_client.get_stats_counts(:opens, :type => :readtimes, :tag => 'foo')
      expect(response).to have_key(:days)
      expect(response).to have_key(:sent)

      first_day = response[:days].first
      expect(first_day).to have_key(:date)
      expect(first_day).to have_key(:sent)
    end
  end

  describe '#get_message_streams' do
    subject(:result) { api_client.get_message_streams(:offset => 22, :count => 33) }

    before do
      allow(http_client).to receive(:get).
        with('message-streams', :offset => 22, :count => 33).
        and_return({ 'TotalCount' => 1, 'MessageStreams' => [{'Name' => 'abc'}]})
    end

    it { is_expected.to be_an(Array) }

    describe 'returned item' do
      subject { result.first }

      it { is_expected.to match(:name => 'abc') }
    end
  end

  describe '#message_streams' do
    subject { api_client.message_streams }

    it { is_expected.to be_kind_of(Enumerable) }

    it 'requests data at /message-streams' do
      allow(http_client).to receive(:get).
        with('message-streams', anything).
        and_return('TotalCount' => 1, 'MessageStreams' => [{}])
      expect(subject.first(5).count).to eq(1)
    end
  end

  describe '#get_message_stream' do
    subject(:result) { api_client.get_message_stream(123) }

    before do
      allow(http_client).to receive(:get).
        with('message-streams/123').
        and_return({
          'Id' => 'xxx',
          'Name' => 'My Stream',
          'ServerID' => 321,
          'MessageStreamType' => 'Transactional'
        })
    end

    it {
      is_expected.to match(
        :id => 'xxx',
        :name => 'My Stream',
        :server_id => 321,
        :message_stream_type => 'Transactional'
      )
    }
  end

  describe '#create_message_stream' do
    subject { api_client.create_message_stream(attrs) }

    let(:attrs) do
      {
        :name => 'My Stream',
        :id => 'my-stream',
        :message_stream_type => 'Broadcasts',
        :subscription_management_configuration => {
          :unsubscribe_handling_type => 'Custom'
        }
      }
    end

    let(:response) do
      {
        'Name' => 'My Stream',
        'Id' => 'my-stream',
        'MessageStreamType' => 'Broadcasts',
        'ServerId' => 222,
        'CreatedAt' => '2020-04-01T03:33:33.333-03:00',
        'SubscriptionManagementConfiguration' => {
          'UnsubscribeHandlingType' => 'Custom'
        }
      }
    end

    before do
      allow(http_client).to receive(:post) { response }
    end

    specify do
      expect(http_client).to receive(:post).
        with('message-streams',
             json_representation_of({
               'Name' => 'My Stream',
               'Id' => 'my-stream',
               'MessageStreamType' => 'Broadcasts',
               'SubscriptionManagementConfiguration' => {
                 'UnsubscribeHandlingType' => 'Custom'
               }
             }))
      subject
    end

    it {
      is_expected.to match(
        :id => 'my-stream',
        :name => 'My Stream',
        :server_id => 222,
        :message_stream_type => 'Broadcasts',
        :created_at => '2020-04-01T03:33:33.333-03:00',
        :subscription_management_configuration => {
          :unsubscribe_handling_type => 'Custom'
        }
      )
    }
  end

  describe '#update_message_stream' do
    subject { api_client.update_message_stream('xxx', attrs) }

    let(:attrs) do
      {
        :name => 'My Stream XXX',
        :subscription_management_configuration => {
          :unsubscribe_handling_type => 'Custom'
        }
      }
    end

    let(:response) do
      {
        'Name' => 'My Stream XXX',
        'Id' => 'xxx',
        'MessageStreamType' => 'Broadcasts',
        'ServerId' => 222,
        'CreatedAt' => '2020-04-01T03:33:33.333-03:00',
        'SubscriptionManagementConfiguration' => {
          'UnsubscribeHandlingType' => 'Custom'
        }
      }
    end

    before do
      allow(http_client).to receive(:patch) { response }
    end

    specify do
      expect(http_client).to receive(:patch).
        with('message-streams/xxx',
             match_json({
               'Name' => 'My Stream XXX',
               'SubscriptionManagementConfiguration' => {
                 'UnsubscribeHandlingType' => 'Custom'
               }
             }))
      subject
    end

    it {
      is_expected.to match(
        :id => 'xxx',
        :name => 'My Stream XXX',
        :server_id => 222,
        :message_stream_type => 'Broadcasts',
        :created_at => '2020-04-01T03:33:33.333-03:00',
        :subscription_management_configuration => {
          :unsubscribe_handling_type => 'Custom'
        }
      )
    }
  end

  describe '#archive_message_stream' do
    subject { api_client.archive_message_stream(stream_id) }

    let(:stream_id) { 'my-stream'}
    let(:server_id) { 123 }
    let(:purge_date) { '2030-08-30T12:30:00.00-04:00' }
    let(:api_endpoint) { "message-streams/#{stream_id}/archive" }
    let(:api_response) {{ 'ID' => stream_id, 'ServerID' => server_id, 'ExpectedPurgeDate' => purge_date  }}

    before do
      allow(http_client).to receive(:post).with(api_endpoint) { api_response }
    end

    it 'calls the API endpoint' do
      expect(http_client).to receive(:post).with(api_endpoint)
      subject
    end

    it 'transforms the API response' do
      expect(subject).to eq({ :id => stream_id, :server_id => server_id, :expected_purge_date => purge_date })
    end
  end

  describe '#unarchive_message_stream' do
    subject { api_client.unarchive_message_stream(stream_id) }

    let(:stream_id) { 'my-stream'}
    let(:server_id) { 123 }
    let(:api_endpoint) { "message-streams/#{stream_id}/unarchive" }
    let(:api_response) {
      { 'ID' => stream_id, 'ServerID' => server_id, 'Name' => 'My Stream',
        'Description' => 'My test stream.', 'MessageStreamType' => 'Transactional',
        'CreatedAt' => '2030-08-30T12:30:00.00-04:00', 'UpdatedAt' => '2030-09-30T12:30:00.00-04:00',
        'ArchivedAt'=> nil, 'ExpectedPurgeDate' => nil,
        'SubscriptionManagementConfiguration' => { 'UnsubscribeHandlingType' => 'None' } }
    }

    before do
      allow(http_client).to receive(:post).with(api_endpoint) { api_response }
    end

    it 'calls the API endpoint' do
      expect(http_client).to receive(:post).with(api_endpoint)
      subject
    end

    it 'transforms the API response' do
      expect(subject).to eq({ :id => stream_id, :server_id => server_id, :name => 'My Stream',
                              :description => 'My test stream.', :message_stream_type => 'Transactional',
                              :created_at => '2030-08-30T12:30:00.00-04:00',
                              :updated_at => '2030-09-30T12:30:00.00-04:00',
                              :archived_at => nil , :expected_purge_date => nil ,
                              :subscription_management_configuration => { 'UnsubscribeHandlingType' => 'None' }})
    end
  end

  describe '#create_suppressions' do
    let(:email_addresses) { nil }
    let(:message_stream_id) { 'outbound' }

    subject { api_client.create_suppressions(message_stream_id, email_addresses) }

    context '1 email address as string' do
      let(:email_addresses) { 'A@example.com' }

      specify do
        expect(http_client).to receive(:post).
          with('message-streams/outbound/suppressions',
               match_json({
                 :Suppressions => [
                   { :EmailAddress => 'A@example.com' }
                 ]}))
        subject
      end
    end

    context '1 email address as string & non-default stream' do
      let(:email_addresses) { 'A@example.com' }
      let(:message_stream_id) { 'xxxx' }

      specify do
        expect(http_client).to receive(:post).
          with('message-streams/xxxx/suppressions',
               match_json({
                 :Suppressions => [
                   { :EmailAddress => 'A@example.com' }
                 ]}))
        subject
      end
    end

    context '1 email address as array of strings' do
      let(:email_addresses) { ['A@example.com'] }

      specify do
        expect(http_client).to receive(:post).
          with('message-streams/outbound/suppressions',
               match_json({
                 :Suppressions => [
                   { :EmailAddress => 'A@example.com' }
                 ]}))
        subject
      end
    end

    context 'many email addresses as array of strings' do
      let(:email_addresses) { ['A@example.com', 'B@example.com'] }

      specify do
        expect(http_client).to receive(:post).
          with('message-streams/outbound/suppressions',
               match_json({
                 :Suppressions => [
                   { :EmailAddress => 'A@example.com' },
                   { :EmailAddress => 'B@example.com' }
                 ]}))
        subject
      end
    end
  end

  describe '#delete_suppressions' do
    let(:email_addresses) { nil }
    let(:message_stream_id) { 'outbound' }

    subject { api_client.delete_suppressions(message_stream_id, email_addresses) }

    context '1 email address as string' do
      let(:email_addresses) { 'A@example.com' }

      specify do
        expect(http_client).to receive(:post).
          with('message-streams/outbound/suppressions/delete',
               match_json({
                 :Suppressions => [
                   { :EmailAddress => 'A@example.com' },
                 ]}))
        subject
      end
    end

    context '1 email address as string & non-default stream' do
      let(:email_addresses) { 'A@example.com' }
      let(:message_stream_id) { 'xxxx' }

      specify do
        expect(http_client).to receive(:post).
          with('message-streams/xxxx/suppressions/delete',
               match_json({
                 :Suppressions => [
                   { :EmailAddress => 'A@example.com' }
                 ]}))
        subject
      end
    end

    context '1 email address as array of strings' do
      let(:email_addresses) { ['A@example.com'] }

      specify do
        expect(http_client).to receive(:post).
          with('message-streams/outbound/suppressions/delete',
               match_json({
                 :Suppressions => [
                   { :EmailAddress => 'A@example.com' }
                 ]}))
        subject
      end
    end

    context 'many email addresses as array of strings' do
      let(:email_addresses) { ['A@example.com', 'B@example.com'] }

      specify do
        expect(http_client).to receive(:post).
          with('message-streams/outbound/suppressions/delete',
               match_json({
                :Suppressions => [
                  { :EmailAddress => 'A@example.com' },
                  { :EmailAddress => 'B@example.com' }
                ]}))
        subject
      end
    end
  end

  describe '#dump_suppressions' do
    let(:message_stream_id) { 'xxxx' }

    subject { api_client.dump_suppressions(message_stream_id, :count => 123) }

    before do
      allow(http_client).to receive(:get).and_return({'TotalCount' => 0, 'Suppressions' => []})
    end

    specify do
      expect(http_client).to receive(:get).
        with('message-streams/xxxx/suppressions/dump', { :count => 123, :offset => 0 })
      subject
    end
  end
end
