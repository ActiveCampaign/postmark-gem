require 'spec_helper'

describe "Bounce" do
  let(:bounce_json) { %{{"Type":"HardBounce","TypeCode":1,"Details":"test bounce","Email":"jim@test.com","BouncedAt":"#{Time.now.to_s}","DumpAvailable":true,"Inactive":false,"CanActivate":true,"ID":12}} }
  let(:bounces_json) { "[#{bounce_json},#{bounce_json}]" }

  it "should retrieve bounce by id" do
    Timecop.freeze do
      FakeWeb.register_uri(:get, "http://api.postmarkapp.com/bounces/12", { :body => bounce_json })
      bounce = Postmark::Bounce.find(12)
      bounce.type.should == "HardBounce"
      bounce.bounced_at.should == Time.now
      bounce.details.should == "test bounce"
      bounce.email.should == "jim@test.com"
    end
  end

  it "should retrieve bounces" do
    Timecop.freeze do
      FakeWeb.register_uri(:get, "http://api.postmarkapp.com/bounces?count=30&offset=0", { :body => bounces_json })
      bounces = Postmark::Bounce.all
      bounces.should have(2).entries
      bounces[0].should be_a(Postmark::Bounce)
    end
  end
end
