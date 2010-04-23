require 'spec_helper'

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

    before(:all) do
      Postmark.sleep_between_retries = 0
    end

    it "should send email successfully" do
      FakeWeb.register_uri(:post, "http://api.postmarkapp.com/email", {})
      Postmark.send_through_postmark(message)
      FakeWeb.should have_requested(:post, "http://api.postmarkapp.com/email")
    end

    it "should warn when header is invalid" do
      FakeWeb.register_uri(:post, "http://api.postmarkapp.com/email", {:status => [ "401", "Unauthorized" ], :body => "Missing API token"})
      lambda { Postmark.send_through_postmark(message) }.should raise_error(Postmark::InvalidApiKeyError)
    end

    it "should warn when json is not ok" do
      FakeWeb.register_uri(:post, "http://api.postmarkapp.com/email", {:status => [ "422", "Invalid" ], :body => "Invalid JSON"})
      lambda { Postmark.send_through_postmark(message) }.should raise_error(Postmark::InvalidMessageError)
    end

    it "should warn when server fails" do
      FakeWeb.register_uri(:post, "http://api.postmarkapp.com/email", {:status => [ "500", "Internal Server Error" ]})
      lambda { Postmark.send_through_postmark(message) }.should raise_error(Postmark::InternalServerError)
    end

    it "should warn when unknown stuff fails" do
      FakeWeb.register_uri(:post, "http://api.postmarkapp.com/email", {:status => [ "485", "Custom HTTP response status" ]})
      lambda { Postmark.send_through_postmark(message) }.should raise_error(Postmark::UnknownError)
    end

    it "should retry 3 times" do
      FakeWeb.register_uri(:post, "http://api.postmarkapp.com/email",
                           [ { :status => [ 500, "Internal Server Error" ] },
                           { :status => [ 500, "Internal Server Error" ] },
                           {  } ]
                          )
      lambda { Postmark.send_through_postmark(message) }.should_not raise_error
    end
  end

  context "delivery stats" do
    let(:response_body) { %{{"InactiveMails":1,"Bounces":[{"TypeCode":0,"Name":"All","Count":2},{"Type":"HardBounce","TypeCode":1,"Name":"Hard bounce","Count":1},{"Type":"SoftBounce","TypeCode":4096,"Name":"Soft bounce","Count":1}]}} }

    it "should query the service for delivery stats" do
      FakeWeb.register_uri(:get, "http://api.postmarkapp.com/deliverystats", { :body => response_body })
      results = Postmark.delivery_stats
      results["InactiveMails"].should == 1
      results["Bounces"].should be_an(Array)
      results["Bounces"].should have(3).entries
      FakeWeb.should have_requested(:get, "http://api.postmarkapp.com/deliverystats")
    end
  end

  context "tmail parse" do
    it "should set text body for plain message" do
      Postmark.send(:convert_tmail, message)['TextBody'].should_not be_nil
    end

    it "should set html body for html message" do
      Postmark.send(:convert_tmail, html_message)['HtmlBody'].should_not be_nil
    end
  end

  def be_serialized_to(json)
    simple_matcher "be serialized to #{json}" do |message|
      Postmark.send(:convert_tmail, message).should == JSON.parse(json)
    end
  end

  it "should encode custom headers headers properly" do
    message["CUSTOM-HEADER"] = "header"
    message.should be_serialized_to %q[{"Subject":"Hello!", "From":"sheldon@bigbangtheory.com", "To":"lenard@bigbangtheory.com", "TextBody":"Hello Sheldon!", "Headers":[{"Name":"Custom-Header", "Value":"header"}]}]
  end

  it "should encode reply to" do
    message.reply_to = ['a@a.com', 'b@b.com']
    message.should be_serialized_to %q[{"Subject":"Hello!", "From":"sheldon@bigbangtheory.com", "ReplyTo":"a@a.com, b@b.com", "To":"lenard@bigbangtheory.com", "TextBody":"Hello Sheldon!"}]
  end

  it "should encode tag" do
    message.tag = "invite"
    message.should be_serialized_to %q[{"Subject":"Hello!", "From":"sheldon@bigbangtheory.com", "Tag":"invite", "To":"lenard@bigbangtheory.com", "TextBody":"Hello Sheldon!"}]
  end

  it "should encode multiple recepients (TO)" do
    message.to = ['a@a.com', 'b@b.com']
    message.should be_serialized_to %q[{"Subject":"Hello!", "From":"sheldon@bigbangtheory.com", "To":"a@a.com, b@b.com", "TextBody":"Hello Sheldon!"}]
  end

  it "should encode multiple recepients (CC)" do
    message.cc = ['a@a.com', 'b@b.com']
    message.should be_serialized_to %q[{"Cc":"a@a.com, b@b.com", "Subject":"Hello!", "From":"sheldon@bigbangtheory.com", "To":"lenard@bigbangtheory.com", "TextBody":"Hello Sheldon!"}]
  end

  it "should encode multiple recepients (BCC)" do
    message.bcc = ['a@a.com', 'b@b.com']
    message.should be_serialized_to %q[{"Bcc":"a@a.com, b@b.com", "Subject":"Hello!", "From":"sheldon@bigbangtheory.com", "To":"lenard@bigbangtheory.com", "TextBody":"Hello Sheldon!"}]
  end

  context "JSON library support" do
    [:Json, :ActiveSupport, :Yajl].each do |lib|
      begin
        original_parser_class = Postmark.response_parser_class

        it "decodes json with #{lib}" do
          Postmark.response_parser_class = lib
          Postmark::Json.decode(%({"Message":"OK"})).should == { "Message" => "OK" }
        end

        Postmark.response_parser_class = original_parser_class
      rescue LoadError # No ActiveSupport or Yajl :(
      end
    end
  end

end
