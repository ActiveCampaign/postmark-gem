require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Postmark" do

  let :message do
    TMail::Mail.new.tap do |mail|
      mail.from = "sheldon@bigbangtheory.com"
      mail.to = "lenard@bigbangtheory.com"
      mail.subject = "Hello!"
      mail.body = "Hello Sheldon!"
    end
  end

  let :html_message do
    TMail::Mail.new.tap do |mail|
      mail.from = "sheldon@bigbangtheory.com"
      mail.to = "lenard@bigbangtheory.com"
      mail.subject = "Hello!"
      mail.body = "<b>Hello Sheldon!</b>"
      mail.content_type = "text/html"
    end
  end

  context "service call" do

    before do
      Postmark.sleep_between_retries = 0
    end

    it "should send email successfully" do
      FakeWeb.register_uri(:post, "http://api.postmarkapp.com/email/", {})
      Postmark.send_through_postmark(message)
      FakeWeb.should have_requested(:post, "http://api.postmarkapp.com/email/")
    end

    it "should warn when header is invalid" do
      FakeWeb.register_uri(:post, "http://api.postmarkapp.com/email/", {:status => [ "401", "Unauthorized" ], :body => "Missing API token"})
      lambda { Postmark.send_through_postmark(message) }.should raise_error(Postmark::InvalidApiKeyError)
    end

    it "should warn when json is not ok" do
      FakeWeb.register_uri(:post, "http://api.postmarkapp.com/email/", {:status => [ "422", "Invalid" ], :body => "Invalid JSON"})
      lambda { Postmark.send_through_postmark(message) }.should raise_error(Postmark::InvalidMessageError)
    end

    it "should warn when server fails" do
      FakeWeb.register_uri(:post, "http://api.postmarkapp.com/email/", {:status => [ "500", "Internal Server Error" ]})
      lambda { Postmark.send_through_postmark(message) }.should raise_error(Postmark::InternalServerError)
    end

    it "should warn when unknown stuff fails" do
      FakeWeb.register_uri(:post, "http://api.postmarkapp.com/email/", {:status => [ "485", "Custom HTTP response status" ]})
      lambda { Postmark.send_through_postmark(message) }.should raise_error(Postmark::UnknownError)
    end

    it "should retry 3 times" do
      FakeWeb.register_uri(:post, "http://api.postmarkapp.com/email/",
                           [ { :status => [ 500, "Internal Server Error" ] },
                           { :status => [ 500, "Internal Server Error" ] },
                           {  } ]
                          )
      lambda { Postmark.send_through_postmark(message) }.should_not raise_error
    end
  end

  context "tmail parse" do
    it "should set text body for plain message" do
      Postmark.convert_tmail(message)['TextBody'].should_not be_nil
    end

    it "should set html body for html message" do
      Postmark.convert_tmail(html_message)['HtmlBody'].should_not be_nil
    end
  end

  context "custom headers" do

    let :message_with_headers do
      TMail::Mail.new.tap do |mail|
        mail.from = "sheldon@bigbangtheory.com"
        mail.to = "lenard@bigbangtheory.com"
        mail.subject = "Hello!"
        mail.body = "Hello Sheldon!"
        mail['CUSTOM-HEADER'] = "header"
        mail.reply_to = ['a@a.com', 'b@b.com']
      end
    end

    it "should encode headers properly" do
      json = %q[{"Subject":"Hello!", "From":"sheldon@bigbangtheory.com", "ReplyTo":"a@a.com, b@b.com", "To":"lenard@bigbangtheory.com", "TextBody":"Hello Sheldon!", "Headers":[{"Name":"Custom-Header", "Value":"header"}]}]
      result = Postmark.convert_tmail(message_with_headers)
      result.should == JSON.parse(json)
    end
  end

  context "JSON library support" do
    [:Json, :ActiveSupport, :Yajl].each do |lib|
      begin
        original_parser_class = Postmark.response_parser_class

        it "decodes json with #{lib}" do
          Postmark.response_parser_class = lib
          Postmark.decode_json(%({"Message":"OK"})).should == { "Message" => "OK" }
        end

        Postmark.response_parser_class = original_parser_class
      rescue LoadError # No ActiveSupport or Yajl :(
      end
    end
  end

end
