require 'spec_helper'

describe Postmark do

  let :tmail_message do
    TMail::Mail.new.tap do |mail|
      mail.from = "sheldon@bigbangtheory.com"
      mail.to = "lenard@bigbangtheory.com"
      mail.subject = "Hello!"
      mail.body = "Hello Sheldon!"
    end
  end

  let :tmail_html_message do
    TMail::Mail.new.tap do |mail|
      mail.from = "sheldon@bigbangtheory.com"
      mail.to = "lenard@bigbangtheory.com"
      mail.subject = "Hello!"
      mail.body = "<b>Hello Sheldon!</b>"
      mail.content_type = "text/html"
    end
  end
  
  let :mail_message do
    Mail.new do
      from    "sheldon@bigbangtheory.com"
      to      "lenard@bigbangtheory.com"
      subject "Hello!"
      body    "Hello Sheldon!"
    end
  end

  let :mail_html_message do
    mail = Mail.new do
      from          "sheldon@bigbangtheory.com"
      to            "lenard@bigbangtheory.com"
      subject       "Hello!"
      html_part do
        body        "<b>Hello Sheldon!</b>"
      end
    end
  end
  
  let :mail_multipart_message do
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

  context "service call" do

    before(:all) do
      Postmark.sleep_between_retries = 0
    end

    def stub_web(data={})
      data[:body] ||= response_body(data[:status].nil? ? 200 : data[:status].first)
      FakeWeb.register_uri(:post, "http://api.postmarkapp.com/email", data)
    end

    def response_body(status, message="")
      body = {"ErrorCode" => status, "Message" => message}.to_json
    end

    it "should send email successfully" do
      stub_web
      Postmark.send_through_postmark(mail_message)
      FakeWeb.should have_requested(:post, "http://api.postmarkapp.com/email")
    end

    it "should warn when header is invalid" do
      stub_web({:status => [ "401", "Unauthorized" ]})
      lambda { Postmark.send_through_postmark(mail_message) }.should raise_error(Postmark::InvalidApiKeyError)
    end

    it "should warn when json is not ok" do
      stub_web({:status => [ "422", "Invalid" ]})
      lambda { Postmark.send_through_postmark(mail_message) }.should raise_error(Postmark::InvalidMessageError)
    end

    it "should warn when server fails" do
      stub_web({:status => [ "500", "Internal Server Error" ]})
      lambda { Postmark.send_through_postmark(mail_message) }.should raise_error(Postmark::InternalServerError)
    end

    it "should warn when unknown stuff fails" do
      stub_web({:status => [ "485", "Custom HTTP response status" ]})
      lambda { Postmark.send_through_postmark(mail_message) }.should raise_error(Postmark::UnknownError)
    end

    it "should retry 3 times" do
      FakeWeb.register_uri(:post, "http://api.postmarkapp.com/email",
                          [ 
                            { :status => [ 500, "Internal Server Error" ], :body => response_body(500, 'Internal Server Error') },
                            { :status => [ 500, "Internal Server Error" ], :body => response_body(500, 'Internal Server Error')  },
                            { :body => response_body(500, 'Internal Server Error')  }
                          ])
      lambda { Postmark.send_through_postmark(mail_message) }.should_not raise_error
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

  context "tmail parse", :ruby => 1.8 do
    subject { tmail_message }
    it_behaves_like :mail    
  end
  
  context "when mail parse" do
    subject { mail_message }
    it_behaves_like :mail

    it "should set html body for html message" do
      Postmark.send(:convert_message_to_options_hash, mail_html_message)['HtmlBody'].should_not be_nil
    end    
  end
  
  context "mail delivery method" do
    it "should be able to set delivery_method" do
      mail_message.delivery_method Mail::Postmark
    end
    
    it "should wrap Postmark.send_through_postmark" do
      message = mail_message
      Postmark.should_receive(:send_through_postmark).with(message)
      mail_message.delivery_method Mail::Postmark
      mail_message.deliver
    end
    
    it "should allow setting of api_key" do
      mail_message.delivery_method Mail::Postmark, {:api_key => 'api-key'}
      mail_message.delivery_method.settings[:api_key].should == 'api-key'
    end
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
