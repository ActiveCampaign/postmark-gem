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

    let(:message_with_open_tracking_false) {
      message.merge(:track_opens => false)
    }

    let(:postmark_message_with_open_tracking) {
      postmark_message.merge("TrackOpens" => true)
    }

    let(:postmark_message_with_open_tracking_false) {
      postmark_message.merge("TrackOpens" => false)
    }

    it 'converts messages without custom headers and attachments correctly' do
      expect(subject.to_postmark(message)).to eq postmark_message
    end

    it 'converts messages with custom headers and without attachments correctly' do
      expect(subject.to_postmark(message_with_headers)).to eq postmark_message_with_headers
    end

    it 'converts messages with custom headers and attachments correctly' do
      expect(subject.to_postmark(message_with_headers_and_attachments)).to eq postmark_message_with_headers_and_attachments
    end

    context 'open tracking flag set' do

      it 'true' do
        expect(subject.to_postmark(message_with_open_tracking)).to eq(postmark_message_with_open_tracking)
      end

      it 'false' do
        expect(subject.to_postmark(message_with_open_tracking_false)).to eq(postmark_message_with_open_tracking_false)
      end

    end

    context 'link tracking flag set' do

      let(:message_with_link_tracking_html) { message.merge(:track_links => :html_only) }
      let(:message_with_link_tracking_text) { message.merge(:track_links => :text_only) }
      let(:message_with_link_tracking_all) { message.merge(:track_links => :html_and_text) }
      let(:message_with_link_tracking_none) { message.merge(:track_links => :none) }

      let(:postmark_message_with_link_tracking_html) { postmark_message.merge("TrackLinks" => 'HtmlOnly') }
      let(:postmark_message_with_link_tracking_text) { postmark_message.merge("TrackLinks" => 'TextOnly') }
      let(:postmark_message_with_link_tracking_all) { postmark_message.merge("TrackLinks" => 'HtmlAndText') }
      let(:postmark_message_with_link_tracking_none) { postmark_message.merge("TrackLinks" => 'None') }

      it 'html' do
        expect(subject.to_postmark(message_with_link_tracking_html)).to eq(postmark_message_with_link_tracking_html)
      end

      it 'text' do
        expect(subject.to_postmark(message_with_link_tracking_text)).to eq(postmark_message_with_link_tracking_text)
      end

      it 'html and text' do
        expect(subject.to_postmark(message_with_link_tracking_all)).to eq(postmark_message_with_link_tracking_all)
      end

      it 'none' do
        expect(subject.to_postmark(message_with_link_tracking_none)).to eq(postmark_message_with_link_tracking_none)
      end

    end

  end

  describe ".headers_to_postmark" do
    it 'converts headers to Postmark format' do
      expect(subject.headers_to_postmark(headers)).to eq postmark_headers
    end

    it 'accepts single header as a non-array' do
      expect(subject.headers_to_postmark(headers.first)).to eq [postmark_headers.first]
    end
  end

  describe ".attachments_to_postmark" do

    it 'converts attachments to Postmark format' do
      expect(subject.attachments_to_postmark(attachments)).to eq postmark_attachments
    end

    it 'accepts single attachment as a non-array' do
      expect(subject.attachments_to_postmark(attachments.first)).to eq [postmark_attachments.first]
    end

  end

end