require 'spec_helper'

describe Postmark::Json do
  let(:data) { {"bar" => "foo", "foo" => "bar"} }

  shared_examples "json parser" do
    it 'encodes and decodes data correctly' do
      hash = Postmark::Json.decode(Postmark::Json.encode(data))
      hash.should have_key("bar")
      hash.should have_key("foo")
    end
  end

  context "given response parser is JSON" do
    before do
      Postmark.response_parser_class = :Json
    end

    it_behaves_like "json parser"
  end

  context "given response parser is ActiveSupport::JSON" do
    before do
      Postmark.response_parser_class = :ActiveSupport
    end

    it_behaves_like "json parser"
  end

  context "given response parser is Yajl", :skip_for_platform => 'java' do
    before do
      Postmark.response_parser_class = :Yajl
    end

    it_behaves_like "json parser"
  end
end