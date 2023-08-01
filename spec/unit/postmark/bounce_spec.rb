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
                       :server_id => 12345,
                       :tag => "TEST_TAG",
                       :message_stream => "my-message-stream",
                       :content => "THE CONTENT",
                       :subject => "Hello from our app!"} }
  let(:bounce_data_postmark) { Postmark::HashHelper.to_postmark(bounce_data) }
  let(:bounces_data) { [bounce_data, bounce_data, bounce_data] }
  let(:bounce) { Postmark::Bounce.new(bounce_data) }

  subject { bounce }

  context "attr readers" do
    it { expect(subject).to respond_to(:email) }
    it { expect(subject).to respond_to(:bounced_at) }
    it { expect(subject).to respond_to(:type) }
    it { expect(subject).to respond_to(:description) }
    it { expect(subject).to respond_to(:details) }
    it { expect(subject).to respond_to(:name) }
    it { expect(subject).to respond_to(:id) }
    it { expect(subject).to respond_to(:server_id) }
    it { expect(subject).to respond_to(:tag) }
    it { expect(subject).to respond_to(:message_id) }
    it { expect(subject).to respond_to(:subject) }
    it { expect(subject).to respond_to(:message_stream) }
    it { expect(subject).to respond_to(:content) }
  end

  context "given a bounce created from bounce_data" do

    it 'is not inactive' do
      expect(subject).not_to be_inactive
    end

    it 'allows to activate the bounce' do
      expect(subject.can_activate?).to be true
    end

    it 'has an available dump' do
      expect(subject.dump_available?).to be true
    end

    its(:type) { is_expected.to eq bounce_data[:type] }
    its(:message_id) { is_expected.to eq bounce_data[:message_id] }
    its(:description) { is_expected.to eq bounce_data[:description] }
    its(:details) { is_expected.to eq bounce_data[:details] }
    its(:email) { is_expected.to eq bounce_data[:email] }
    its(:bounced_at) { is_expected.to eq Time.parse(bounce_data[:bounced_at]) }
    its(:id) { is_expected.to eq bounce_data[:id] }
    its(:subject) { is_expected.to eq bounce_data[:subject] }
    its(:message_stream) { is_expected.to eq bounce_data[:message_stream] }
    its(:server_id) { is_expected.to eq bounce_data[:server_id] }
    its(:tag) { is_expected.to eq bounce_data[:tag] }
    its(:content) { is_expected.to eq bounce_data[:content] }

  end

  context "given a bounce created from bounce_data_postmark" do
    subject { Postmark::Bounce.new(bounce_data_postmark) }

    it 'is not inactive' do
      expect(subject).not_to be_inactive
    end

    it 'allows to activate the bounce' do
      expect(subject.can_activate?).to be true
    end

    it 'has an available dump' do
      expect(subject.dump_available?).to be true
    end

    its(:type) { is_expected.to eq bounce_data[:type] }
    its(:message_id) { is_expected.to eq bounce_data[:message_id] }
    its(:details) { is_expected.to eq bounce_data[:details] }
    its(:email) { is_expected.to eq bounce_data[:email] }
    its(:bounced_at) { is_expected.to eq Time.parse(bounce_data[:bounced_at]) }
    its(:id) { is_expected.to eq bounce_data[:id] }
    its(:subject) { is_expected.to eq bounce_data[:subject] }
  end

  describe "#dump" do
    let(:bounce_body) { double }
    let(:response) { {:body => bounce_body} }
    let(:api_client) { Postmark.api_client }

    it "calls #dump_bounce on shared api_client instance" do
      expect(Postmark.api_client).to receive(:dump_bounce).with(bounce.id) { response }
      expect(bounce.dump).to eq bounce_body
    end
  end

  describe "#activate" do
    let(:api_client) { Postmark.api_client }

    it "calls #activate_bounce on shared api_client instance" do
      expect(api_client).to receive(:activate_bounce).with(bounce.id) { bounce_data }
      expect(bounce.activate).to be_a Postmark::Bounce
    end
  end

  describe ".find" do
    let(:api_client) { Postmark.api_client }

    it "calls #get_bounce on shared api_client instance" do
      expect(api_client).to receive(:get_bounce).with(42) { bounce_data }
      expect(Postmark::Bounce.find(42)).to be_a Postmark::Bounce
    end
  end

  describe ".all" do
    let(:response) { bounces_data }
    let(:api_client) { Postmark.api_client }

    it "calls #get_bounces on shared api_client instance" do
      expect(api_client).to receive(:get_bounces) { response }
      expect(Postmark::Bounce.all.count).to eq(3)
    end
  end
end