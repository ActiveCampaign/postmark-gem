require 'spec_helper'

describe Postmark::Json do
  let(:json_dump) { "{\"bar\":\"foo\",\"foo\":\"bar\"}" }
  let(:data) { {"bar" => "foo", "foo" => "bar"} }

  context "given response parser is JSON" do
    before do
      Postmark.response_parser_class = :Json
    end

    it 'encodes data correctly' do
      Postmark::Json.encode(data).should == json_dump
    end

    it 'decodes data correctly' do
      Postmark::Json.decode(json_dump).should == data
    end
  end

  context "given response parser is ActiveSupport::JSON" do
    before do
      Postmark.response_parser_class = :ActiveSupport
    end

    it 'encodes data correctly' do
      Postmark::Json.encode(data).should == json_dump
    end

    it 'decodes data correctly' do
      Postmark::Json.decode(json_dump).should == data
    end
  end

  context "given response parser is Yajl" do
    before do
      Postmark.response_parser_class = :Yajl
    end

    it 'encodes data correctly' do
      Postmark::Json.encode(data).should == json_dump
    end

    it 'decodes data correctly' do
      Postmark::Json.decode(json_dump).should == data
    end
  end
end