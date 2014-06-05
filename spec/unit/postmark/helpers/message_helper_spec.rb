require 'spec_helper'

describe Postmark::MessageHelper do
  let(:attachments) {
    [
      File.open(empty_gif_path),
      {:name => "img2.gif",
       :content => Postmark::MessageHelper.encode_in_base64(File.read(empty_gif_path)),
       :content_type => "application/octet-stream"}
    ]
  }

  let(:postmark_attachments) {
    content = Postmark::MessageHelper.encode_in_base64(File.read(empty_gif_path))
    [
      {"Name" => "empty.gif",
       "Content" => content,
       "ContentType" => "application/octet-stream"},
      {"Name" => "img2.gif",
       "Content" => content,
       "ContentType" => "application/octet-stream"}
    ]
  }

  let(:headers) {
    [{:name => "CUSTOM-HEADER", :value => "value"}]
  }

  let(:postmark_headers) {
    [{"Name" => "CUSTOM-HEADER", "Value" => "value"}]
  }


  describe ".to_postmark" do
    let(:message) {
      {
        :from => "sender@example.com",
        :to => "receiver@example.com",
        :cc => "copied@example.com",
        :bcc => "blank-copied@example.com",
        :subject => "Test",
        :tag => "Invitation",
        :html_body => "<b>Hello</b>",
        :text_body => "Hello",
        :reply_to => "reply@example.com"
      }
    }

    let(:postmark_message) {
      {
        "From" => "sender@example.com",
        "To" => "receiver@example.com",
        "Cc" => "copied@example.com",
        "Bcc"=> "blank-copied@example.com",
        "Subject" => "Test",
        "Tag" => "Invitation",
        "HtmlBody" => "<b>Hello</b>",
        "TextBody" => "Hello",
        "ReplyTo" => "reply@example.com",
      }
    }

    let(:message_with_headers) {
      message.merge(:headers => headers)
    }

    let(:postmark_message_with_headers) {
      postmark_message.merge("Headers" => postmark_headers)
    }

    let(:message_with_headers_and_attachments) {
      message_with_headers.merge(:attachments => attachments)
    }

    let(:postmark_message_with_headers_and_attachments) {
      postmark_message_with_headers.merge("Attachments" => postmark_attachments)
    }

    let(:message_with_open_tracking) {
      message.merge(:track_opens => true)
    }

    let(:postmark_message_with_open_tracking) {
      postmark_message.merge("TrackOpens" => true)
    }

    it 'converts messages without custom headers and attachments correctly' do
      subject.to_postmark(message).should == postmark_message
    end

    it 'converts messages with custom headers and without attachments correctly' do
      subject.to_postmark(message_with_headers).should == postmark_message_with_headers
    end

    it 'converts messages with custom headers and attachments correctly' do
      subject.to_postmark(message_with_headers_and_attachments).should == postmark_message_with_headers_and_attachments
    end

    it 'includes open tracking flag when specified' do
      expect(subject.to_postmark(message_with_open_tracking)).to eq(postmark_message_with_open_tracking)
    end

  end

  describe ".headers_to_postmark" do
    it 'converts headers to Postmark format' do
      subject.headers_to_postmark(headers).should == postmark_headers
    end

    it 'accepts single header as a non-array' do
      subject.headers_to_postmark(headers.first).should == [postmark_headers.first]
    end
  end

  describe ".attachments_to_postmark" do

    it 'converts attachments to Postmark format' do
      subject.attachments_to_postmark(attachments).should == postmark_attachments
    end

    it 'accepts single attachment as a non-array' do
      subject.attachments_to_postmark(attachments.first).should == [postmark_attachments.first]
    end

  end

end