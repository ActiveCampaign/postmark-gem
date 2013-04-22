require 'spec_helper'

describe Mail::Message do
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

  describe "#to_postmark_hash" do
    it 'converts plain text messages correctly' do
      mail_message.to_postmark_hash.should == {
          "From" => "sheldon@bigbangtheory.com",
          "Subject" => "Hello!",
          "TextBody" => "Hello Sheldon!",
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
  end
end