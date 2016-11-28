# encoding: utf-8
require 'spec_helper'

describe Postmark::MailMessageConverter do

  subject { Postmark::MailMessageConverter }

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

  let(:mail_message_with_open_tracking) do
    Mail.new do
      from          "sheldon@bigbangtheory.com"
      to            "lenard@bigbangtheory.com"
      subject       "Hello!"
      content_type  'text/html; charset=UTF-8'
      body          "<b>Hello Sheldon!</b>"
      track_opens   true
    end
  end

  let(:mail_message_with_open_tracking_disabled) do
    Mail.new do
      from          "sheldon@bigbangtheory.com"
      to            "lenard@bigbangtheory.com"
      subject       "Hello!"
      content_type  'text/html; charset=UTF-8'
      body          "<b>Hello Sheldon!</b>"
      track_opens   false
    end
  end

  let(:mail_message_with_open_tracking_set_variable) do
    mail = mail_html_message
    mail.track_opens=true
    mail
  end

  let(:mail_message_with_open_tracking_disabled_set_variable) do
    mail = mail_html_message
    mail.track_opens=false
    mail
  end

  let(:mail_message_with_link_tracking_all) do
    mail = mail_html_message
    mail.track_links   :html_and_text
    mail
  end

  let(:mail_message_with_link_tracking_html) do
    mail = mail_html_message
    mail.track_links = :html_only
    mail
  end

  let(:mail_message_with_link_tracking_text) do
    mail = mail_html_message
    mail.track_links = :text_only
    mail
  end

  let(:mail_message_with_link_tracking_none) do
    mail = mail_html_message
    mail.track_links = :none
    mail
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

  let(:mail_multipart_message) do
    Mail.new do
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
      reply_to '"Penny The Neighbor" <penny@bigbangtheory.com>'
    end
  end

  let(:mail_message_quoted_printable) do
    Mail.new do
      from    "Sheldon <sheldon@bigbangtheory.com>"
      to      "\"Leonard Hofstadter\" <leonard@bigbangtheory.com>"
      subject "Hello!"
      content_type 'text/plain; charset=utf-8'
      content_transfer_encoding 'quoted-printable'
      body    'Он здесь бывал: еще не в галифе.'
      reply_to '"Penny The Neighbor" <penny@bigbangtheory.com>'
    end
  end

  let(:multipart_message_quoted_printable) do
    Mail.new do
      from          "sheldon@bigbangtheory.com"
      to            "lenard@bigbangtheory.com"
      subject       "Hello!"
      text_part do
        content_type 'text/plain; charset=utf-8'
        content_transfer_encoding 'quoted-printable'
        body 'Загадочное послание.'
      end
      html_part do
        content_type 'text/html; charset=utf-8'
        content_transfer_encoding 'quoted-printable'
        body '<b>Загадочное послание.</b>'
      end
    end
  end

  it 'converts plain text messages correctly' do
    subject.new(mail_message).run.should == {
        "From" => "sheldon@bigbangtheory.com",
        "Subject" => "Hello!",
        "TextBody" => "Hello Sheldon!",
        "To" => "lenard@bigbangtheory.com"}
  end

  it 'converts tagged text messages correctly' do
    subject.new(tagged_mail_message).run.should == {
        "From" => "sheldon@bigbangtheory.com",
        "Subject" => "Hello!",
        "TextBody" => "Hello Sheldon!",
        "Tag" => "sheldon",
        "To"=>"lenard@bigbangtheory.com"}
  end

  it 'converts plain text messages without body correctly' do
    subject.new(mail_message_without_body).run.should == {
        "From" => "sheldon@bigbangtheory.com",
        "Subject" => "Hello!",
        "To" => "lenard@bigbangtheory.com"}
  end

  it 'converts html messages correctly' do
    subject.new(mail_html_message).run.should == {
        "From" => "sheldon@bigbangtheory.com",
        "Subject" => "Hello!",
        "HtmlBody" => "<b>Hello Sheldon!</b>",
        "To" => "lenard@bigbangtheory.com"}
  end

  it 'converts multipart messages correctly' do
    subject.new(mail_multipart_message).run.should == {
        "From" => "sheldon@bigbangtheory.com",
        "Subject" => "Hello!",
        "HtmlBody" => "<b>Hello Sheldon!</b>",
        "TextBody" => "Hello Sheldon!",
        "To" => "lenard@bigbangtheory.com"}
  end

  it 'converts messages with attachments correctly' do
    subject.new(mail_message_with_attachment).run.should == {
        "From" => "sheldon@bigbangtheory.com",
        "Subject" => "Hello!",
        "Attachments" => [{"Name"=>"empty.gif",
                           "Content"=>encoded_empty_gif_data,
                           "ContentType"=>"image/gif"}],
        "TextBody"=>"Hello Sheldon!",
        "To"=>"lenard@bigbangtheory.com"}
  end

  it 'converts messages with named addresses correctly' do
    subject.new(mail_message_with_named_addresses).run.should == {
        "From" => "Sheldon <sheldon@bigbangtheory.com>",
        "Subject" => "Hello!",
        "TextBody" => "Hello Sheldon!",
        "To" => "Leonard Hofstadter <leonard@bigbangtheory.com>",
        "ReplyTo" => 'Penny The Neighbor <penny@bigbangtheory.com>'}
  end

  context 'recognizes open tracking' do

    context 'setup inside of mail' do

      it 'enabled' do
        expect(subject.new(mail_message_with_open_tracking).run).to eq ({
            "From" => "sheldon@bigbangtheory.com",
            "Subject" => "Hello!",
            "HtmlBody" => "<b>Hello Sheldon!</b>",
            "To" => "lenard@bigbangtheory.com",
            "TrackOpens" => true})
      end

      it 'disabled' do
        expect(subject.new(mail_message_with_open_tracking_disabled).run).to eq ({
            "From" => "sheldon@bigbangtheory.com",
            "Subject" => "Hello!",
            "HtmlBody" => "<b>Hello Sheldon!</b>",
            "To" => "lenard@bigbangtheory.com",
            "TrackOpens" => false})
      end

    end

    context 'setup with tracking variable' do

      it 'enabled' do
        expect(subject.new(mail_message_with_open_tracking_set_variable).run).to eq ({
            "From" => "sheldon@bigbangtheory.com",
            "Subject" => "Hello!",
            "HtmlBody" => "<b>Hello Sheldon!</b>",
            "To" => "lenard@bigbangtheory.com",
            "TrackOpens" => true})
      end

      it 'disabled' do
        expect(subject.new(mail_message_with_open_tracking_disabled_set_variable).run).to eq ({
            "From" => "sheldon@bigbangtheory.com",
            "Subject" => "Hello!",
            "HtmlBody" => "<b>Hello Sheldon!</b>",
            "To" => "lenard@bigbangtheory.com",
            "TrackOpens" => false})
      end

    end

  end

  context 'link tracking' do

    it 'html and text' do
      expect(subject.new(mail_message_with_link_tracking_all).run).to eq ({
          "From" => "sheldon@bigbangtheory.com",
          "Subject" => "Hello!",
          "HtmlBody" => "<b>Hello Sheldon!</b>",
          "To" => "lenard@bigbangtheory.com",
          "TrackLinks" => 'HtmlAndText'})
    end

    it 'html only' do
      expect(subject.new(mail_message_with_link_tracking_html).run).to eq ({
          "From" => "sheldon@bigbangtheory.com",
          "Subject" => "Hello!",
          "HtmlBody" => "<b>Hello Sheldon!</b>",
          "To" => "lenard@bigbangtheory.com",
          "TrackLinks" => 'HtmlOnly'})
    end

    it 'text only' do
      expect(subject.new(mail_message_with_link_tracking_text).run).to eq ({
          "From" => "sheldon@bigbangtheory.com",
          "Subject" => "Hello!",
          "HtmlBody" => "<b>Hello Sheldon!</b>",
          "To" => "lenard@bigbangtheory.com",
          "TrackLinks" => 'TextOnly'})
    end

    it 'none' do
      expect(subject.new(mail_message_with_link_tracking_none).run).to eq ({
          "From" => "sheldon@bigbangtheory.com",
          "Subject" => "Hello!",
          "HtmlBody" => "<b>Hello Sheldon!</b>",
          "To" => "lenard@bigbangtheory.com",
          "TrackLinks" => 'None'})
    end

  end

  it 'correctly decodes unicode in messages transfered as quoted-printable' do
    subject.new(mail_message_quoted_printable).run.should \
      include('TextBody' => 'Он здесь бывал: еще не в галифе.')
  end

  it 'correctly decodes unicode in multipart quoted-printable messages' do
    subject.new(multipart_message_quoted_printable).run.should \
      include('TextBody' => 'Загадочное послание.',
              'HtmlBody' => '<b>Загадочное послание.</b>')
  end

  context 'when bcc is empty' do
    it 'excludes bcc from message' do
      mail_message.bcc = nil
      mail_message.to_postmark_hash.keys.should_not include('Bcc')
    end
  end

  context 'when cc is empty' do
    it 'excludes cc from message' do
      mail_message.cc = nil
      mail_message.to_postmark_hash.keys.should_not include('Cc')
    end
  end

end
