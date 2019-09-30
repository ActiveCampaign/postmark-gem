require 'spec_helper'

describe Postmark::Inflector do
  describe ".to_postmark" do
    it 'converts rubyish underscored format to camel cased symbols accepted by the Postmark API' do
      expect(subject.to_postmark(:foo_bar)).to eq 'FooBar'
      expect(subject.to_postmark(:_bar)).to eq 'Bar'
      expect(subject.to_postmark(:really_long_long_long_long_symbol)).to eq 'ReallyLongLongLongLongSymbol'
      expect(subject.to_postmark(:foo_bar_1)).to eq 'FooBar1'
    end

    it 'accepts strings as well' do
      expect(subject.to_postmark('foo_bar')).to eq 'FooBar'
    end

    it 'acts idempotentely' do
      expect(subject.to_postmark('FooBar')).to eq 'FooBar'
    end
  end

  describe ".to_ruby" do
    it 'converts camel cased symbols returned by the Postmark API to underscored Ruby symbols' do
      expect(subject.to_ruby('FooBar')).to eq :foo_bar
      expect(subject.to_ruby('LongTimeAgoInAFarFarGalaxy')).to eq :long_time_ago_in_a_far_far_galaxy
      expect(subject.to_ruby('MessageID')).to eq :message_id
    end

    it 'acts idempotentely' do
      expect(subject.to_ruby(:foo_bar)).to eq :foo_bar
      expect(subject.to_ruby(:foo_bar_1)).to eq :foo_bar_1
    end
  end
end