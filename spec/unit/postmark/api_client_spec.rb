require 'spec_helper'

describe Postmark::ApiClient do

  let(:api_token) { "provided-api-token" }
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

  let(:api_client) { Postmark::ApiClient.new(api_token) }
  subject { api_client }

  context "attr readers" do
    it { should respond_to(:http_client) }
    it { should respond_to(:max_retries) }
  end

  context "when it's created without options" do

    its(:max_retries) { should eq 3 }

  end

  context "when it's created with user options" do

    subject { Postmark::ApiClient.new(api_token, :max_retries => max_retries,
                                               :foo => :bar)}

    its(:max_retries) { should eq max_retries }

    it 'passes other options to HttpClient instance' do
      Postmark::HttpClient.should_receive(:new).with(api_token, :foo => :bar)
      subject.should be
    end

  end

  describe "#api_token=" do

    let(:api_token) { "new-api-token-value" }

    it 'assigns the api token to the http client instance' do
      subject.api_token = api_token
      subject.http_client.api_token.should == api_token
    end

    it 'is aliased as api_key=' do
      subject.api_key = api_token
      subject.http_client.api_token.should == api_token
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
    let(:email_json) { Postmark::Json.encode(email) }
    let(:http_client) { subject.http_client }

    it 'turns message into a JSON document and posts it to /email' do
      http_client.should_receive(:post).with('email', email_json)
      subject.deliver_message(message)
    end

    it "retries 3 times" do
      2.times do
        http_client.should_receive(:post).and_raise(Postmark::InternalServerError)
      end
      http_client.should_receive(:post)
      expect { subject.deliver_message(message) }.not_to raise_error
    end

    it "retries on timeout" do
      http_client.should_receive(:post).and_raise(Postmark::TimeoutError)
      http_client.should_receive(:post)
      expect { subject.deliver_message(message) }.not_to raise_error
    end

    it "proxies errors" do
      http_client.stub(:post).and_raise(Postmark::TimeoutError)
      expect { subject.deliver_message(message) }.to raise_error(Postmark::TimeoutError)
    end

  end

  describe "#deliver_messages" do

    let(:email) { message.to_postmark_hash }
    let(:emails) { [email, email, email] }
    let(:emails_json) { Postmark::Json.encode(emails) }
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

  describe '#messages' do

    context 'given outbound' do

      let(:response) {
        {'TotalCount' => 5,
         'Messages' => [{}].cycle(5).to_a}
      }

      it 'returns an enumerator' do
        expect(subject.messages).to be_kind_of(Enumerable)
      end

      it 'loads outbound messages' do
        allow(subject.http_client).to receive(:get).
            with('messages/outbound', an_instance_of(Hash)).and_return(response)
        expect(subject.messages.count).to eq(5)
      end

    end

    context 'given inbound' do

      let(:response) {
        {'TotalCount' => 5,
         'InboundMessages' => [{}].cycle(5).to_a}
      }

      it 'returns an enumerator' do
        expect(subject.messages(:inbound => true)).to be_kind_of(Enumerable)
      end

      it 'loads inbound messages' do
        allow(subject.http_client).to receive(:get).
            with('messages/inbound', an_instance_of(Hash)).and_return(response)
        expect(subject.messages(:inbound => true).count).to eq(5)
      end

    end

  end

  describe '#get_messages' do
    let(:http_client) { subject.http_client }

    context 'given outbound' do
      let(:response) { {"TotalCount" => 1, "Messages" => [{}]} }

      it 'requests data at /messages/outbound' do
        http_client.should_receive(:get).
                    with('messages/outbound', :offset => 50, :count => 50).
                    and_return(response)
        subject.get_messages(:offset => 50, :count => 50)
      end

    end

    context 'given inbound' do
      let(:response) { {"TotalCount" => 1, "InboundMessages" => [{}]} }

      it 'requests data at /messages/inbound' do
        http_client.should_receive(:get).
                    with('messages/inbound', :offset => 50, :count => 50).
                    and_return(response)
        subject.get_messages(:inbound => true, :offset => 50, :count => 50).
                should be_an(Array)
      end

    end
  end

  describe '#get_messages_count' do

    let(:response) { {'TotalCount' => 42} }

    context 'given outbound' do

      it 'requests and returns outbound messages count' do
        allow(subject.http_client).to receive(:get).
            with('messages/outbound', an_instance_of(Hash)).and_return(response)
        expect(subject.get_messages_count).to eq(42)
        expect(subject.get_messages_count(:inbound => false)).to eq(42)
      end

    end

    context 'given inbound' do

      it 'requests and returns inbound messages count' do
        allow(subject.http_client).to receive(:get).
            with('messages/inbound', an_instance_of(Hash)).and_return(response)
        expect(subject.get_messages_count(:inbound => true)).to eq(42)
      end

    end

  end

  describe '#get_message' do
    let(:id) { '8ad0e8b0-xxxx-xxxx-951d-223c581bb467' }
    let(:http_client) { subject.http_client }
    let(:response) { {"To" => "leonard@bigbangtheory.com"} }

    context 'given outbound' do

      it 'requests a single message by id at /messages/outbound/:id/details' do
        http_client.should_receive(:get).
                    with("messages/outbound/#{id}/details", {}).
                    and_return(response)
        subject.get_message(id).should have_key(:to)
      end

    end

    context 'given inbound' do

      it 'requests a single message by id at /messages/inbound/:id/details' do
        http_client.should_receive(:get).
                    with("messages/inbound/#{id}/details", {}).
                    and_return(response)
        subject.get_message(id, :inbound => true).should have_key(:to)
      end

    end
  end

  describe '#dump_message' do
    let(:id) { '8ad0e8b0-xxxx-xxxx-951d-223c581bb467' }
    let(:http_client) { subject.http_client }
    let(:response) { {"Body" => "From: <leonard@bigbangtheory.com> \r\n ..."} }

    context 'given outbound' do

      it 'requests a single message by id at /messages/outbound/:id/dump' do
        http_client.should_receive(:get).
                    with("messages/outbound/#{id}/dump", {}).
                    and_return(response)
        subject.dump_message(id).should have_key(:body)
      end

    end

    context 'given inbound' do

      it 'requests a single message by id at /messages/inbound/:id/dump' do
        http_client.should_receive(:get).
                    with("messages/inbound/#{id}/dump", {}).
                    and_return(response)
        subject.dump_message(id, :inbound => true).should have_key(:body)
      end

    end
  end

  describe '#bounces' do

    it 'returns an Enumerator' do
      expect(subject.bounces).to be_kind_of(Enumerable)
    end

    it 'requests data at /bounces' do
      allow(subject.http_client).to receive(:get).
          with('bounces', an_instance_of(Hash)).
          and_return('TotalCount' => 1, 'Bounces' => [{}])
      expect(subject.bounces.first(5).count).to eq(1)
    end

  end

  describe "#get_bounces" do
    let(:http_client) { subject.http_client }
    let(:options) { {:foo => :bar} }
    let(:response) { {"Bounces" => []} }

    it 'requests data at /bounces' do
      allow(http_client).to receive(:get).with("bounces", options) { response }
      expect(subject.get_bounces(options)).to be_an(Array)
      expect(subject.get_bounces(options).count).to be_zero
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

  describe '#opens' do

    it 'returns an Enumerator' do
      expect(subject.opens).to be_kind_of(Enumerable)
    end

    it 'performs a GET request to /opens/tags' do
      allow(subject.http_client).to receive(:get).
          with('messages/outbound/opens', an_instance_of(Hash)).
          and_return('TotalCount' => 1, 'Opens' => [{}])
      expect(subject.opens.first(5).count).to eq(1)
    end

  end

  describe '#get_opens' do
    let(:http_client) { subject.http_client }
    let(:options) { {:offset => 5} }
    let(:response) { {'Opens' => [], 'TotalCount' => 0} }

    it 'performs a GET request to /messages/outbound/opens' do
      allow(http_client).to receive(:get).with('messages/outbound/opens', options) { response }
      expect(subject.get_opens(options)).to be_an(Array)
      expect(subject.get_opens(options).count).to be_zero
    end
  end

  describe '#get_opens_by_message_id' do
    let(:http_client) { subject.http_client }
    let(:message_id) { 42 }
    let(:options) { {:offset => 5} }
    let(:response) { {'Opens' => [], 'TotalCount' => 0} }

    it 'performs a GET request to /messages/outbound/opens' do
      allow(http_client).
          to receive(:get).with("messages/outbound/opens/#{message_id}",
                                options).
                           and_return(response)
      expect(subject.get_opens_by_message_id(message_id, options)).to be_an(Array)
      expect(subject.get_opens_by_message_id(message_id, options).count).to be_zero
    end
  end

  describe '#opens_by_message_id' do
    let(:message_id) { 42 }

    it 'returns an Enumerator' do
      expect(subject.opens_by_message_id(message_id)).to be_kind_of(Enumerable)
    end

    it 'performs a GET request to /opens/tags' do
      allow(subject.http_client).to receive(:get).
          with("messages/outbound/opens/#{message_id}", an_instance_of(Hash)).
          and_return('TotalCount' => 1, 'Opens' => [{}])
      expect(subject.opens_by_message_id(message_id).first(5).count).to eq(1)
    end
  end

  describe '#create_trigger' do
    let(:http_client) { subject.http_client }
    let(:options) { {:foo => 'bar'} }
    let(:response) { {'Foo' => 'Bar'} }

    it 'performs a POST request to /triggers/tags with given options' do
      allow(http_client).to receive(:post).with('triggers/tags',
                                                {'Foo' => 'bar'}.to_json)
      subject.create_trigger(:tags, options)
    end

    it 'symbolizes response keys' do
      allow(http_client).to receive(:post).and_return(response)
      expect(subject.create_trigger(:tags, options)).to eq(:foo => 'Bar')
    end
  end

  describe '#get_trigger' do
    let(:http_client) { subject.http_client }
    let(:id) { 42 }

    it 'performs a GET request to /triggers/tags/:id' do
      allow(http_client).to receive(:get).with("triggers/tags/#{id}")
      subject.get_trigger(:tags, id)
    end

    it 'symbolizes response keys' do
      allow(http_client).to receive(:get).and_return('Foo' => 'Bar')
      expect(subject.get_trigger(:tags, id)).to eq(:foo => 'Bar')
    end
  end

  describe '#update_trigger' do
    let(:http_client) { subject.http_client }
    let(:options) { {:foo => 'bar'} }
    let(:id) { 42 }

    it 'performs a PUT request to /triggers/tags/:id' do
      allow(http_client).to receive(:put).with("triggers/tags/#{id}",
                                               {'Foo' => 'bar'}.to_json)
      subject.update_trigger(:tags, id, options)
    end

    it 'symbolizes response keys' do
      allow(http_client).to receive(:put).and_return('Foo' => 'Bar')
      expect(subject.update_trigger(:tags, id, options)).to eq(:foo => 'Bar')
    end
  end

  describe '#delete_trigger' do
    let(:http_client) { subject.http_client }
    let(:id) { 42 }

    it 'performs a DELETE request to /triggers/tags/:id' do
      allow(http_client).to receive(:delete).with("triggers/tags/#{id}")
      subject.delete_trigger(:tags, id)
    end

    it 'symbolizes response keys' do
      allow(http_client).to receive(:delete).and_return('Foo' => 'Bar')
      expect(subject.delete_trigger(:tags, id)).to eq(:foo => 'Bar')
    end
  end

  describe '#get_triggers' do
    let(:http_client) { subject.http_client }
    let(:options) { {:offset => 5} }
    let(:response) { {'Tags' => [], 'TotalCount' => 0} }

    it 'performs a GET request to /triggers/tags' do
      allow(http_client).to receive(:get).with('triggers/tags', options) { response }
      expect(subject.get_triggers(:tags, options)).to be_an(Array)
      expect(subject.get_triggers(:tags, options).count).to be_zero
    end
  end

  describe '#triggers' do

    it 'returns an Enumerator' do
      expect(subject.triggers(:tags)).to be_kind_of(Enumerable)
    end

    it 'performs a GET request to /triggers/tags' do
      allow(subject.http_client).to receive(:get).
          with('triggers/tags', an_instance_of(Hash)).
          and_return('TotalCount' => 1, 'Tags' => [{}])
      expect(subject.triggers(:tags).first(5).count).to eq(1)
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
      http_client.should_receive(:put).with('server', anything) { response }
      subject.update_server_info(update)[:smtp_api_activated].should be_false
    end
  end

  describe '#get_templates' do
    let(:http_client) { subject.http_client }
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
      http_client.should_receive(:get).with('templates', :offset => 0, :count => 2).and_return(response)

      count, templates = subject.get_templates(:count => 2)

      expect(count).to eq(31)
      expect(templates.first[:template_id]).to eq(123)
      expect(templates.first[:name]).to eq('ABC')
    end
  end

  describe '#templates' do
    it 'returns an Enumerator' do
      expect(subject.templates).to be_kind_of(Enumerable)
    end

    it 'requests data at /templates' do
      allow(subject.http_client).to receive(:get).
          with('templates', an_instance_of(Hash)).
          and_return('TotalCount' => 1, 'Templates' => [{}])
      expect(subject.templates.first(5).count).to eq(1)
    end
  end

  describe '#get_template' do
    let(:http_client) { subject.http_client }
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
      http_client.should_receive(:get).with('templates/123').and_return(response)

      template = subject.get_template('123')

      expect(template[:name]).to eq('Template Name')
      expect(template[:template_id]).to eq(123)
      expect(template[:html_body]).to eq('Html')
    end
  end

  describe '#create_template' do
    let(:http_client) { subject.http_client }
    let(:response) do
      {
        'TemplateId' => 123,
        'Name' => 'template name',
        'Active' => true
      }
    end

    it 'performs a POST request to /templates with the given attributes' do
      expected_json = { 'Name' => 'template name' }.to_json

      http_client.should_receive(:post).with('templates', expected_json).and_return(response)

      template = subject.create_template(:name => 'template name')

      expect(template[:name]).to eq('template name')
      expect(template[:template_id]).to eq(123)
    end
  end

  describe '#update_template' do
    let(:http_client) { subject.http_client }
    let(:response) do
      {
        'TemplateId' => 123,
        'Name' => 'template name',
        'Active' => true
      }
    end

    it 'performs a PUT request to /templates with the given attributes' do
      expected_json = { 'Name' => 'template name' }.to_json

      http_client.should_receive(:put).with('templates/123', expected_json).and_return(response)

      template = subject.update_template(123, :name => 'template name')

      expect(template[:name]).to eq('template name')
      expect(template[:template_id]).to eq(123)
    end
  end

  describe '#delete_template' do
    let(:http_client) { subject.http_client }
    let(:response) do
      {
        'ErrorCode' => 0,
        'Message' => 'Template 123 removed.'
      }
    end

    it 'performs a DELETE request to /templates/:id' do
      http_client.should_receive(:delete).with('templates/123').and_return(response)

      resp = subject.delete_template(123)

      expect(resp[:error_code]).to eq(0)
    end
  end

  describe '#validate_template' do
    let(:http_client) { subject.http_client }

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
        expected_template_json = {
          'HtmlBody' => '{{MyName}}',
          'TextBody' => '{{MyName}}',
          'Subject' => '{{MyName}}'
        }.to_json

        http_client.should_receive(:post).with('templates/validate', expected_template_json).and_return(response)

        resp = subject.validate_template(:html_body => '{{MyName}}',
                                         :text_body => '{{MyName}}',
                                         :subject => '{{MyName}}')

        expect(resp[:all_content_is_valid]).to be_true
        expect(resp[:html_body][:content_is_valid]).to be_true
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
        expected_template_json = {
          'HtmlBody' => '{{#each}}',
          'TextBody' => '{{MyName}}',
          'Subject' => '{{MyName}}'
        }.to_json

        http_client.should_receive(:post).with('templates/validate', expected_template_json).and_return(response)

        resp = subject.validate_template(:html_body => '{{#each}}',
                                         :text_body => '{{MyName}}',
                                         :subject => '{{MyName}}')

        expect(resp[:all_content_is_valid]).to be_false
        expect(resp[:text_body][:content_is_valid]).to be_true
        expect(resp[:html_body][:content_is_valid]).to be_false
        expect(resp[:html_body][:validation_errors].first[:character_position]).to eq(1)
        expect(resp[:html_body][:validation_errors].first[:message]).to eq('The \'each\' block being opened requires a model path to be specified in the form \'{#each <name>}\'.')
      end
    end
  end

  describe "#deliver_with_template" do
    let(:email) { Postmark::MessageHelper.to_postmark(message_hash) }
    let(:email_json) { Postmark::Json.encode(email) }
    let(:http_client) { subject.http_client }
    let(:response) { {"MessageID" => 42} }

    it 'converts message hash to Postmark format and posts it to /email/withTemplate' do
      http_client.should_receive(:post).with('email/withTemplate', email_json) { response }
      subject.deliver_with_template(message_hash)
    end

    it 'retries 3 times' do
      2.times do
        http_client.should_receive(:post).and_raise(Postmark::InternalServerError)
      end
      http_client.should_receive(:post) { response }
      expect { subject.deliver_with_template(message_hash) }.not_to raise_error
    end

    it 'converts response to ruby format' do
      http_client.should_receive(:post).with('email/withTemplate', email_json) { response }
      r = subject.deliver_with_template(message_hash)
      r.should have_key(:message_id)
    end
  end

  describe '#get_stats_totals' do
    let(:response) do
      {
        "Sent" => 615,
        "BounceRate" => 10.406,
      }
    end
    let(:http_client) { subject.http_client }

    it 'converts response to ruby format' do
      http_client.should_receive(:get).with('stats/outbound', { :tag => 'foo' }) { response }
      r = subject.get_stats_totals(:tag => 'foo')
      r.should have_key(:sent)
      r.should have_key(:bounce_rate)
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
    let(:http_client) { subject.http_client }

    it 'converts response to ruby format' do
      http_client.should_receive(:get).with('stats/outbound/sends', { :tag => 'foo' }) { response }
      r = subject.get_stats_counts(:sends, :tag => 'foo')
      r.should have_key(:days)
      r.should have_key(:sent)

      first_day = r[:days].first

      first_day.should have_key(:date)
      first_day.should have_key(:sent)
    end

    it 'uses fromdate that is passed in' do
      http_client.should_receive(:get).with('stats/outbound/sends', { :tag => 'foo', :fromdate => '2015-01-01' }) { response }
      r = subject.get_stats_counts(:sends, :tag => 'foo', :fromdate => '2015-01-01')
      r.should have_key(:days)
      r.should have_key(:sent)

      first_day = r[:days].first

      first_day.should have_key(:date)
      first_day.should have_key(:sent)
    end

    it 'uses stats type that is passed in' do
      http_client.should_receive(:get).with('stats/outbound/opens/readtimes', { :tag => 'foo', :type => :readtimes }) { response }
      r = subject.get_stats_counts(:opens, :type => :readtimes, :tag => 'foo')
      r.should have_key(:days)
      r.should have_key(:sent)

      first_day = r[:days].first

      first_day.should have_key(:date)
      first_day.should have_key(:sent)
    end
  end
end
