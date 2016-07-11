require 'spec_helper'

describe Postmark::Bounce do
  let(:bounce_data) { {:type => "HardBounce",
                       :message_id => "d12c2f1c-60f3-4258-b163-d17052546ae4",
                       :type_code => 1,
                       :description => "The server was unable to deliver your message (ex: unknown user, mailbox not found).",
                       :details => "test bounce",
                       :email => "jim@test.com",
                       :bounced_at => "2013-04-22 18:06:48 +0800",
                       :dump_available => true,
                       :inactive => false,
                       :can_activate => true,
                       :id => 42,
                       :subject => "Hello from our app!"} }
  let(:bounce_data_postmark) { Postmark::HashHelper.to_postmark(bounce_data) }
  let(:bounces_data) { [bounce_data, bounce_data, bounce_data] }

  let(:bounce) { Postmark::Bounce.new(bounce_data) }

  subject { bounce }

  context "attr readers" do

    it { should respond_to(:email) }
    it { should respond_to(:bounced_at) }
    it { should respond_to(:type) }
    it { should respond_to(:description) }
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

    its(:type) { should eq bounce_data[:type] }
    its(:message_id) { should eq bounce_data[:message_id] }
    its(:description) { should eq bounce_data[:description] }
    its(:details) { should eq bounce_data[:details] }
    its(:email) { should eq bounce_data[:email] }
    its(:bounced_at) { should == Time.parse(bounce_data[:bounced_at]) }
    its(:id) { should eq bounce_data[:id] }
    its(:subject) { should eq bounce_data[:subject] }

  end

  context "given a bounce created from bounce_data_postmark" do
    subject { Postmark::Bounce.new(bounce_data_postmark) }

    it 'is not inactive' do
      should_not be_inactive
    end

    it 'allows to activate the bounce' do
      subject.can_activate?.should be_true
    end

    it 'has an available dump' do
      subject.dump_available?.should be_true
    end

    its(:type) { should eq bounce_data[:type] }
    its(:message_id) { should eq bounce_data[:message_id] }
    its(:details) { should eq bounce_data[:details] }
    its(:email) { should eq bounce_data[:email] }
    its(:bounced_at) { should == Time.parse(bounce_data[:bounced_at]) }
    its(:id) { should eq bounce_data[:id] }
    its(:subject) { should eq bounce_data[:subject] }

  end

  describe "#dump" do

    let(:bounce_body) { double }
    let(:response) { {:body => bounce_body} }
    let(:api_client) { Postmark.api_client }

    it "calls #dump_bounce on shared api_client instance" do
      Postmark.api_client.should_receive(:dump_bounce).with(bounce.id) { response }
      bounce.dump.should == bounce_body
    end

  end

  describe "#activate" do

    let(:api_client) { Postmark.api_client }

    it "calls #activate_bounce on shared api_client instance" do
      api_client.should_receive(:activate_bounce).with(bounce.id) { bounce_data }
      bounce.activate.should be_a Postmark::Bounce
    end

  end

  describe ".find" do
    let(:api_client) { Postmark.api_client }

    it "calls #get_bounce on shared api_client instance" do
      api_client.should_receive(:get_bounce).with(42) { bounce_data }
      Postmark::Bounce.find(42).should be_a Postmark::Bounce
    end
  end

  describe ".all" do

    let(:response) { bounces_data }
    let(:api_client) { Postmark.api_client }

    it "calls #get_bounces on shared api_client instance" do
      api_client.should_receive(:get_bounces) { response }
      Postmark::Bounce.all.should have(3).bounces
    end

  end

  describe ".tags" do

    let(:api_client) { Postmark.api_client }
    let(:tags) { ["tag1", "tag2"] }

    it "calls #get_bounced_tags on shared api_client instance" do
      api_client.should_receive(:get_bounced_tags) { tags }
      Postmark::Bounce.tags.should == tags
    end
  end

end