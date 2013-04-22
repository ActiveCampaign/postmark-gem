require 'spec_helper'

describe Postmark::Bounce do

  let(:bounce_data) { {"Type" => "HardBounce",
                       "MessageID" => "d12c2f1c-60f3-4258-b163-d17052546ae4",
                       "TypeCode" => 1,
                       "Details" => "test bounce",
                       "Email" => "jim@test.com",
                       "BouncedAt" => "2013-04-22 18:06:48 +0800",
                       "DumpAvailable" => true,
                       "Inactive" => false,
                       "CanActivate" => true,
                       "ID" => 12,
                       "Subject" => "Hello from our app!"} }
  let(:bounces_data) { [bounce_data, bounce_data, bounce_data] }

  let(:bounce) { Postmark::Bounce.new(bounce_data) }

  subject { bounce }

  context "attr readers" do

    it { should respond_to(:email) }
    it { should respond_to(:bounced_at) }
    it { should respond_to(:type) }
    it { should respond_to(:details) }
    it { should respond_to(:name) }
    it { should respond_to(:id) }
    it { should respond_to(:server_id) }
    it { should respond_to(:tag) }
    it { should respond_to(:message_id) }
    it { should respond_to(:subject) }

  end

  context "given a bounce created from bounce_data" do

    it 'is not inactive' do
      should_not be_inactive
    end

    it 'allows to activate the bounce' do
      subject.can_activate?.should be_true
    end

    it 'has an available dump' do
      subject.dump_available?.should be_true
    end

    its(:type) { should eq bounce_data["Type"] }
    its(:message_id) { should eq bounce_data["MessageID"] }
    its(:details) { should eq bounce_data["Details"] }
    its(:email) { should eq bounce_data["Email"] }
    its(:bounced_at) { should == Time.parse(bounce_data["BouncedAt"]) }
    its(:id) { should eq bounce_data["ID"] }
    its(:subject) { should eq bounce_data["Subject"] }

  end

  describe "#dump" do

    let(:bounce_body) { mock }
    let(:response) { {"Body" => bounce_body} }
    let(:api_client) { Postmark.api_client }

    it "calls #dump_bounce on shared api_client instance" do
      Postmark.api_client.should_receive(:dump_bounce).with(bounce.id) { response }
      bounce.dump.should == bounce_body
    end

  end

  describe "#activate" do

    let(:response) { {"Bounce" => bounce_data} }
    let(:api_client) { Postmark.api_client }

    it "calls #activate_bounce on shared api_client instance" do
      Postmark.api_client.should_receive(:activate_bounce).with(bounce.id) { response }
      bounce.activate.should be_a Postmark::Bounce
    end

  end

  describe ".all" do
    let(:response) { {"Bounces" => bounces_data} }
    let(:api_client) { Postmark.api_client }

    it "calls #get_bounces on shared api_client instance" do
      Postmark.api_client.should_receive(:get_bounces) { response }
      Postmark::Bounce.all.should have(3).bounces
    end
  end

end