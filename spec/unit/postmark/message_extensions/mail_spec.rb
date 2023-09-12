require 'spec_helper'

describe Mail::Message do
  before do
    allow(Kernel).to receive(:warn)
  end

  let(:mail_message) do
    Mail.new do
      from    "sheldon@bigbangtheory.com"
      to      "lenard@bigbangtheory.com"
      subject "Hello!"
      body    "Hello Sheldon!"
    end
  end

  let(:mail_html_message) do
    Mail.new do
      from          "sheldon@bigbangtheory.com"
      to            "lenard@bigbangtheory.com"
      subject       "Hello!"
      content_type 'text/html; charset=UTF-8'
      body "<b>Hello Sheldon!</b>"
    end
  end

  let(:templated_message) do
    Mail.new do
      from           "sheldon@bigbangtheory.com"
      to             "lenard@bigbangtheory.com"
      template_alias "Hello!"
      template_model :name => "Sheldon"
    end
  end

  describe '#tag' do

    it 'value set on tag=' do
      mail_message.tag='value'
      expect(mail_message.tag).to eq 'value'
    end

    it 'value set on tag()' do
      mail_message.tag('value')
      expect(mail_message.tag).to eq 'value'
    end

  end

  describe '#track_opens' do
    it 'returns nil if unset' do
      expect(mail_message.track_opens).to eq ''
    end

    context 'when assigned via #track_opens=' do
      it 'returns assigned value to track opens' do
        mail_message.track_opens = true
        expect(mail_message.track_opens).to eq 'true'
      end

      it 'returns assigned value to not track opens' do
        mail_message.track_opens = false
        expect(mail_message.track_opens).to eq 'false'
      end
    end

    context 'flag set on track_opens()' do
      it 'true' do
        mail_message.track_opens(true)
        expect(mail_message.track_opens).to eq 'true'
      end

      it 'false' do
        mail_message.track_opens(false)
        expect(mail_message.track_opens).to eq 'false'
      end
    end
  end

  describe '#metadata' do
    let(:metadata) { { :test => 'test' } }

    it 'returns a mutable empty hash if unset' do
      expect(mail_message.metadata).to eq({})
      expect(mail_message.metadata.equal?(mail_message.metadata)).to be true
    end

    it 'supports assigning non-null values (for the builder DSL)' do
      expect { mail_message.metadata(metadata) }.to change { mail_message.metadata }.to(metadata)
      expect { mail_message.metadata(nil) }.to_not change { mail_message.metadata }
    end

    it 'returns value assigned via metadata=' do
      expect { mail_message.metadata = metadata }.to change { mail_message.metadata }.to(metadata)
    end
  end

  describe '#track_links' do
    it 'return empty string when if unset' do
      expect(mail_message.track_links).to eq ''
    end

    context 'when assigned via #track_links=' do
      it 'returns track html only body value in Postmark format' do
        mail_message.track_links=:html_only
        expect(mail_message.track_links).to eq 'HtmlOnly'
      end
    end

    context 'when assigned via track_links()' do
      it 'returns track html only body value in Postmark format' do
        mail_message.track_links(:html_only)
        expect(mail_message.track_links).to eq 'HtmlOnly'
      end
    end
  end

  describe "#html?" do
    it 'is true for html only email' do
      expect(mail_html_message).to be_html
    end
  end

  describe "#body_html" do
    it 'returns html body if present' do
      expect(mail_html_message.body_html).to eq "<b>Hello Sheldon!</b>"
    end
  end

  describe "#body_text" do
    it 'returns text body if present' do
      expect(mail_message.body_text).to eq "Hello Sheldon!"
    end
  end

  describe "#postmark_attachments=" do
    let(:attached_hash) { {'Name' => 'picture.jpeg',
                           'ContentType' => 'image/jpeg'} }

    it "stores attachments as an array" do
      mail_message.postmark_attachments = attached_hash
      expect(mail_message.instance_variable_get(:@_attachments)).to include(attached_hash)
    end

    it "is deprecated" do
      expect(Kernel).to receive(:warn).with(/deprecated/)
      mail_message.postmark_attachments = attached_hash
    end
  end

  describe "#postmark_attachments" do
    let(:attached_file) { double("file") }
    let(:attached_hash) { {'Name' => 'picture.jpeg',
                           'ContentType' => 'image/jpeg'} }
    let(:exported_file) { {'Name' => 'file.jpeg',
                           'ContentType' => 'application/octet-stream',
                           'Content' => ''} }

    before do
      allow(attached_file).to receive(:is_a?) { |arg| arg == File ? true : false }
      allow(attached_file).to receive(:path) { '/tmp/file.jpeg' }
    end

    it "supports multiple attachment formats" do
      expect(IO).to receive(:read).with("/tmp/file.jpeg").and_return("")

      mail_message.postmark_attachments = [attached_hash, attached_file]
      attachments = mail_message.export_attachments

      expect(attachments).to include(attached_hash)
      expect(attachments).to include(exported_file)
    end

    it "is deprecated" do
      mail_message.postmark_attachments = attached_hash
      expect(Kernel).to receive(:warn).with(/deprecated/)
      mail_message.postmark_attachments
    end
  end

  describe "#export_attachments" do
    let(:file_data) { 'binarydatahere' }
    let(:exported_data) {
      {'Name' => 'face.jpeg',
       'Content' => "YmluYXJ5ZGF0YWhlcmU=\n",
       'ContentType' => 'image/jpeg; filename=face.jpeg'}
    }

    context 'given a regular attachment' do

      it "exports native attachments" do
        mail_message.attachments["face.jpeg"] = file_data
        expect(mail_message.export_attachments).to include(exported_data)
      end

      it "still supports the deprecated attachments API" do
        mail_message.attachments["face.jpeg"] = file_data
        mail_message.postmark_attachments = exported_data
        expect(mail_message.export_attachments).to eq [exported_data, exported_data]
      end

    end

    context 'given an inline attachment' do

      it "exports the attachment with related content id" do
        mail_message.attachments.inline["face.jpeg"] = file_data
        attachments = mail_message.export_attachments

        expect(attachments.count).to_not be_zero
        expect(attachments.first).to include(exported_data)
        expect(attachments.first).to have_key('ContentID')
        expect(attachments.first['ContentID']).to start_with('cid:')
      end

    end

  end

  describe "#export_headers" do
    let(:mail_message_with_reserved_headers) do
      mail_message.header['Return-Path'] = 'bounce@postmarkapp.com'
      mail_message.header['From'] = 'info@postmarkapp.com'
      mail_message.header['Sender'] = 'info@postmarkapp.com'
      mail_message.header['Received'] = 'from mta.pstmrk.it ([72.14.252.155]:54907)'
      mail_message.header['Date'] = 'January 25, 2013 3:30:58 PM PDT'
      mail_message.header['Content-Type'] = 'application/json'
      mail_message.header['To'] = 'lenard@bigbangtheory.com'
      mail_message.header['Cc'] = 'sheldon@bigbangtheory.com'
      mail_message.header['Bcc'] = 'penny@bigbangtheory.com'
      mail_message.header['Subject'] = 'You want not to use a bogus header'
      mail_message.header['Tag'] = 'bogus-tag'
      mail_message.header['Attachment'] = 'anydatahere'
      mail_message.header['Allowed-Header'] = 'value'
      mail_message.header['TRACK-OPENS'] = 'true'
      mail_message.header['TRACK-LINKS'] = 'HtmlOnly'
      mail_message
    end


    it 'only allowed headers' do
      headers = mail_message_with_reserved_headers.export_headers
      header_names = headers.map { |h| h['Name'] }

      aggregate_failures do
        expect(header_names).to include('Allowed-Header')
        expect(header_names.count).to eq 1
      end
    end

    it 'custom header character case preserved' do
      custom_header = {"Name"=>"custom-Header", "Value"=>"cUsTomHeaderValue"}
      mail_message.header[custom_header['Name']] = custom_header['Value']

      expect(mail_message.export_headers.first).to match(custom_header)
    end
  end

  describe "#to_postmark_hash" do
    # See mail_message_converter_spec.rb
  end

  describe '#templated?' do
    it { expect(mail_message).to_not be_templated }
    it { expect(templated_message).to be_templated }
  end

  describe '#prerender' do
    let(:model) { templated_message.template_model }
    let(:model_text) { model[:name] }

    let(:template_response) do
      {
        :html_body => '<html><body>{{ name }}</body></html>',
        :text_body => '{{ name }}'
      }
    end

    let(:successful_render_response) do
      {
        :all_content_is_valid => true,
        :subject => {
          :rendered_content => 'Subject'
        },
        :text_body => {
          :rendered_content => model_text
        },
        :html_body => {
          :rendered_content => "<html><body>#{model_text}</body></html>"
        }
      }
    end

    let(:failed_render_response) do
      {
        :all_content_is_valid => false,
        :subject => {
          :rendered_content => 'Subject'
        },
        :text_body => {
          :rendered_content => model_text
        },
        :html_body => {
          :rendered_content => nil,
          :validation_errors => [
            { :message => 'The syntax for this template is invalid.', :line => 1, :character_position => 1 }
          ]
        }
      }
    end

    subject(:rendering) { message.prerender }

    context 'when called on a non-templated message' do
      let(:message) { mail_message }

      it 'raises a Postmark::Error' do
        expect { rendering }.to raise_error(Postmark::Error, /Cannot prerender/)
      end
    end

    context 'when called on a templated message' do
      let(:message) { templated_message }

      before do
        message.delivery_method delivery_method
      end

      context 'and using a non-Postmark delivery method' do
        let(:delivery_method) { Mail::SMTP }

        it { expect { rendering }.to raise_error(Postmark::MailAdapterError) }
      end

      context 'and using a Postmark delivery method' do
        let(:delivery_method) { Mail::Postmark }

        before do
          expect_any_instance_of(Postmark::ApiClient).
            to receive(:get_template).with(message.template_alias).
            and_return(template_response)
          expect_any_instance_of(Postmark::ApiClient).
            to receive(:validate_template).with(template_response.merge(:test_render_model => model)).
            and_return(render_response)
        end

        context 'and rendering succeeds' do
          let(:render_response) { successful_render_response }

          it 'sets HTML and Text parts to rendered values' do
            expect { rendering }.
              to change { message.subject }.to(render_response[:subject][:rendered_content]).
              and change { message.body_text }.to(render_response[:text_body][:rendered_content]).
              and change { message.body_html }.to(render_response[:html_body][:rendered_content])
          end
        end

        context 'and rendering fails' do
          let(:render_response) { failed_render_response }

          it 'raises Postmark::InvalidTemplateError' do
            expect { rendering }.to raise_error(Postmark::InvalidTemplateError)
          end
        end
      end
    end
  end
end
