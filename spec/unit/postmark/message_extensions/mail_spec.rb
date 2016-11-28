require 'spec_helper'

describe Mail::Message do
  before do
    Kernel.stub(:warn)
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

  let(:mail_message_with_bogus_headers) do
    mail_message.header['Return-Path'] = 'bounce@wildbit.com'
    mail_message.header['From'] = 'info@wildbit.com'
    mail_message.header['Sender'] = 'info@wildbit.com'
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

    context 'flag set on track_opens=' do

      it 'true' do
        mail_message.track_opens = true
        expect(mail_message.track_opens).to eq 'true'
      end

      it 'false' do
        mail_message.track_opens = false
        expect(mail_message.track_opens).to eq 'false'
      end

      it 'not set' do
        expect(mail_message.track_opens).to eq ''
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

  describe '#track_links' do

    context 'flag set on track_links=' do

      it 'set' do
        mail_message.track_links=:html_only
        expect(mail_message.track_links).to eq 'HtmlOnly'
      end

      it 'not set' do
        expect(mail_message.track_links).to eq ''
      end

    end

    context 'flag set on track_links()' do

      it 'set' do
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
      Kernel.should_receive(:warn).with(/deprecated/)
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
      attached_file.stub(:is_a?) { |arg| arg == File ? true : false }
      attached_file.stub(:path) { '/tmp/file.jpeg' }
    end

    it "supports multiple attachment formats" do
      IO.should_receive(:read).with("/tmp/file.jpeg").and_return("")

      mail_message.postmark_attachments = [attached_hash, attached_file]
      attachments = mail_message.export_attachments

      expect(attachments).to include(attached_hash)
      expect(attachments).to include(exported_file)
    end

    it "is deprecated" do
      mail_message.postmark_attachments = attached_hash
      Kernel.should_receive(:warn).with(/deprecated/)
      mail_message.postmark_attachments
    end
  end

  describe "#export_attachments" do
    let(:file_data) { 'binarydatahere' }
    let(:exported_data) {
      {'Name' => 'face.jpeg',
       'Content' => "YmluYXJ5ZGF0YWhlcmU=\n",
       'ContentType' => 'image/jpeg'}
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
    let(:headers) { mail_message_with_bogus_headers.export_headers }
    let(:header_names) { headers.map { |h| h['Name'] } }

    specify { expect(header_names).to include('Allowed-Header') }
    specify { expect(header_names.count).to eq 1 }
  end

  describe "#to_postmark_hash" do
    # See mail_message_converter_spec.rb
  end

end
