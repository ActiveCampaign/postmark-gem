require 'spec_helper'

describe "Bounce" do
  let(:response_body) { %{{"Type":"HardBounce","TypeCode":1,"Details":"test bounce","Email":"jim@test.com","BouncedAt":"#{Time.now.to_s}","DumpAvailable":true,"Inactive":false,"CanActivate":true,"ID": [ID]}} }

  it "should retrieve bounce by id" do
    Timecop.freeze do
      FakeWeb.register_uri(:get, "http://api.postmarkapp.com/bounces/12", { :body => response_body })
      bounce = Postmark::Bounce.find(12)
      bounce.type.should == "HardBounce"
      bounce.bounced_at.should == Time.now
      bounce.details.should == "test bounce"
      bounce.email.should == "jim@test.com"
    end
  end
end
