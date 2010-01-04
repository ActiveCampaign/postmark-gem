require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Postmark" do
  context "configuration" do
    it "should allow configuration of host" do
      Postmark.configure { |config| config.host = "test" }
      Postmark.host.should == "test"
    end
  end

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

  let :net_http_proxy do
    stub(:new => http_request)
  end

  def http_response(code)
    Net::HTTPResponse.new("1.1", code, nil).tap do |resp|
      resp.stub! :body => '{ "Message": "OK" }'
    end
  end

  let :http_response_ok do
    http_response(200)
  end

  let :http_response_unauthorized do
    http_response(401)
  end

  let :http_response_invalid do
    http_response(422)
  end

  let :http_response_server_error do
    http_response(500)
  end

  let :http_response_unknown do
    http_response(503)
  end

  let :http_request do
    stub(:read_timeout= => nil, :open_timeout= => nil, :use_ssl= => nil)
  end

  before do
    Net::HTTP.stub!(:Proxy).and_return(net_http_proxy)
  end

  context "service call" do
    it "should send email successfully" do
      http_request.stub! :post => http_response_ok
      lambda { Postmark.send_through_postmark(message) }.should_not raise_error
    end

    it "should warn when header is invalid" do
      http_request.stub! :post => http_response_unauthorized
      lambda { Postmark.send_through_postmark(message) }.should raise_error(Postmark::InvalidApiKeyError)
    end

    it "should warn when json is not ok" do
      http_request.stub! :post => http_response_invalid
      lambda { Postmark.send_through_postmark(message) }.should raise_error(Postmark::InvalidMessageError)
    end

    it "should warn when server fails" do
      http_request.stub! :post => http_response_server_error
      lambda { Postmark.send_through_postmark(message) }.should raise_error(Postmark::InternalServerError)
    end

    it "should warn when unknown stuff fails" do
      http_request.stub! :post => http_response_unknown
      lambda { Postmark.send_through_postmark(message) }.should raise_error(Postmark::UnknownError)
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
      json = %q[{"Subject":"Hello!", "From":"sheldon@bigbangtheory.com", "ReplyTo":"a@a.com, b@b.com", "To":"lenard@bigbangtheory.com", "TextBody":"Hello Sheldon!", "Headers":[{"Name":"CUSTOM-HEADER", "Value":"header"}]}]
      result = Postmark.convert_tmail(message_with_headers)
      result.should == JSON.parse(json)
    end
  end

  context "JSON library support" do
    [:Json, :ActiveSupport, :Yajl].each do |lib|
      begin
        original_parser_class = Postmark.response_parser_class
        Postmark.response_parser_class = lib
        it "parses error message with #{lib}" do
          Postmark.error_message(%({"Message":"OK"})).should == "OK"
        end
        Postmark.response_parser_class = original_parser_class
      rescue LoadError # No ActiveSupport or Yajl :(
      end
    end
  end

end
