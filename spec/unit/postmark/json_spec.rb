require 'spec_helper'

describe Postmark::Json do
  let(:json_dump) { "{\"foo\":\"bar\",\"bar\":\"foo\"}" }
  let(:data) { {"foo" => "bar", "bar" => "foo"} }

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

  context "given response parser is Yahl" do
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