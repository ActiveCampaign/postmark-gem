require 'spec_helper'

describe Postmark::Client do

  subject { Postmark::Client.new('abcd-efgh') }

  describe 'instance' do

    describe '#find_each' do

      let(:path) { 'resources' }
      let(:name) { 'Resources' }
      let(:response) {
        {
          'TotalCount' => 10,
          name => [{'Foo' => 'bar'}, {'Bar' => 'foo'}]
        }
      }

      it 'returns an enumerator' do
        expect(subject.find_each(path, name)).to be_kind_of(Enumerable)
      end

      it 'can be iterated' do
        collection = [{:foo => 'bar'}, {:bar => 'foo'}].cycle(5)
        allow(subject.http_client).
            to receive(:get).with(path, an_instance_of(Hash)).
                             exactly(5).times.and_return(response)
        expect { |b| subject.find_each(path, name, :count => 2).each(&b) }.
            to yield_successive_args(*collection)
      end

      # Only Ruby >= 2.0.0 supports Enumerator#size
      it 'lazily calculates the collection size',
        :skip_ruby_version => ['1.8.7', '1.9'] do
        allow(subject.http_client).
            to receive(:get).exactly(1).times.and_return(response)
        collection = subject.find_each(path, name, :count => 2)
        expect(collection.size).to eq(10)
      end

      it 'iterates over the collection to count it' do
        allow(subject.http_client).
            to receive(:get).exactly(5).times.and_return(response)
        expect(subject.find_each(path, name, :count => 2).count).to eq(10)
      end

    end

  end

end