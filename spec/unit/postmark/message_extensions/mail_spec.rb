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

  let(:tagged_mail_message) do
    Mail.new do
      from    "sheldon@bigbangtheory.com"
      to      "lenard@bigbangtheory.com"
      subject "Hello!"
      body    "Hello Sheldon!"
      tag     "sheldon"
    end
  end

  let(:mail_message_without_body) do
    Mail.new do
      from    "sheldon@bigbangtheory.com"
      to      "lenard@bigbangtheory.com"
      subject "Hello!"
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

  let(:mail_multipart_message) do
    mail = Mail.new do
      from          "sheldon@bigbangtheory.com"
      to            "lenard@bigbangtheory.com"
      subject       "Hello!"
      text_part do
        body        "Hello Sheldon!"
      end
      html_part do
        body        "<b>Hello Sheldon!</b>"
      end
    end
  end

  let(:mail_message_with_attachment) do
    Mail.new do
      from    "sheldon@bigbangtheory.com"
      to      "lenard@bigbangtheory.com"
      subject "Hello!"
      body    "Hello Sheldon!"
      add_file empty_gif_path
    end
  end

  let(:mail_message_with_named_addresses) do
    Mail.new do
      from    "Sheldon <sheldon@bigbangtheory.com>"
      to      "\"Leonard Hofstadter\" <leonard@bigbangtheory.com>"
      subject "Hello!"
      body    "Hello Sheldon!"
      reply_to 'Penny "The Neighbor" <penny@bigbangtheory.com>'
    end
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
    let(:attached_file) { mock("file") }
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
    let(:exported_data) do
      {'Name' => 'face.jpeg',
       'Content' => "YmluYXJ5ZGF0YWhlcmU=\n",
       'ContentType' => 'image/jpeg'}
    end

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

  describe "#to_postmark_hash" do
    it 'converts plain text messages correctly' do
      mail_message.to_postmark_hash.should == {
          "From" => "sheldon@bigbangtheory.com",
          "Subject" => "Hello!",
          "TextBody" => "Hello Sheldon!",
          "To" => "lenard@bigbangtheory.com"}
    end

    it 'converts tagged text messages correctly' do
      tagged_mail_message.to_postmark_hash.should == {
          "From" => "sheldon@bigbangtheory.com",
          "Subject" => "Hello!",
          "TextBody" => "Hello Sheldon!",
          "Tag" => "sheldon",
          "To"=>"lenard@bigbangtheory.com"}
    end

    it 'converts plain text messages without body correctly' do
      mail_message_without_body.to_postmark_hash.should == {
          "From" => "sheldon@bigbangtheory.com",
          "Subject" => "Hello!",
          "To" => "lenard@bigbangtheory.com"}
    end

    it 'converts html messages correctly' do
      mail_html_message.to_postmark_hash.should == {
          "From" => "sheldon@bigbangtheory.com",
          "Subject" => "Hello!",
          "HtmlBody" => "<b>Hello Sheldon!</b>",
          "To" => "lenard@bigbangtheory.com"}
    end

    it 'converts multipart messages correctly' do
      mail_multipart_message.to_postmark_hash.should == {
          "From" => "sheldon@bigbangtheory.com",
          "Subject" => "Hello!",
          "HtmlBody" => "<b>Hello Sheldon!</b>",
          "TextBody" => "Hello Sheldon!",
          "To" => "lenard@bigbangtheory.com"}
    end

    it 'converts messages with attachments correctly' do
      mail_message_with_attachment.to_postmark_hash.should == {
          "From" => "sheldon@bigbangtheory.com",
          "Subject" => "Hello!",
          "Attachments" => [{"Name"=>"empty.gif",
                             "Content"=>encoded_empty_gif_data,
                             "ContentType"=>"image/gif"}],
          "TextBody"=>"Hello Sheldon!",
          "To"=>"lenard@bigbangtheory.com"}
    end

    it 'converts messages with named addresses correctly' do
      mail_message_with_named_addresses.to_postmark_hash.should == {
          "From" => "Sheldon <sheldon@bigbangtheory.com>",
          "Subject" => "Hello!",
          "TextBody" => "Hello Sheldon!",
          "To" => "Leonard Hofstadter <leonard@bigbangtheory.com>",
          "ReplyTo" => "\"Penny \\\"The Neighbor\\\"\" <penny@bigbangtheory.com>"
      }
    end
  end
end