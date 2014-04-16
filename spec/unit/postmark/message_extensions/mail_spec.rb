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
    mail = Mail.new do
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
    mail_message
  end

  describe "#html?" do
    it 'is true for html only email' do
      mail_html_message.should be_html
    end
  end

  describe "#body_html" do
    it 'returns html body if present' do
      mail_html_message.body_html.should == "<b>Hello Sheldon!</b>"
    end
  end

  describe "#body_text" do
    it 'returns text body if present' do
      mail_message.body_text.should == "Hello Sheldon!"
    end
  end

  describe "#postmark_attachments=" do
    let(:attached_hash) { {'Name' => 'picture.jpeg',
                           'ContentType' => 'image/jpeg'} }

    it "stores attachments as an array" do
      mail_message.postmark_attachments = attached_hash
      mail_message.instance_variable_get(:@_attachments).should include(attached_hash)
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

      attachments.should include(attached_hash)
      attachments.should include(exported_file)
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
        mail_message.export_attachments.should include(exported_data)
      end

      it "still supports the deprecated attachments API" do
        mail_message.attachments["face.jpeg"] = file_data
        mail_message.postmark_attachments = exported_data
        mail_message.export_attachments.should == [exported_data, exported_data]
      end

    end

    context 'given an inline attachment' do

      it "exports the attachment with related content id" do
        mail_message.attachments.inline["face.jpeg"] = file_data
        attachments = mail_message.export_attachments
        attachments.count.should_not be_zero
        attachments.first.should include(exported_data)
        attachments.first.should have_key('ContentID')
        attachments.first['ContentID'].should start_with('cid:')
      end

    end

  end

  describe "#export_headers" do
    let(:headers) { mail_message_with_bogus_headers.export_headers }
    let(:header_names) { headers.map { |h| h['Name'] } }

    specify { header_names.should include('Allowed-Header') }
    specify { header_names.count.should == 1 }
  end

  describe "#to_postmark_hash" do
    # See mail_message_converter_spec.rb
  end

end
