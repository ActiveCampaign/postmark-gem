require 'spec_helper'

describe Postmark::HashHelper do
  describe ".to_postmark" do
    let(:source) do
      {
        :level_one => {
          :level_two => {
            :level_three => [{ :array_item => 1 }]
          }
        }
      }
    end

    describe 'default behaviour' do
      let(:target) do
        {
          'LevelOne' => {
            :level_two => {
              :level_three => [{ :array_item => 1 }]
            }
          }
        }
      end

      it 'does not convert nested elements' do
        expect(subject.to_postmark(source)).to eq(target)
      end
    end

    describe 'deep conversion' do
      let(:target) do
        {
          'LevelOne' => {
            'LevelTwo' => {
              'LevelThree' => [{ 'ArrayItem' => 1 }]
            }
          }
        }
      end

      it 'converts nested elements when requested' do
        expect(subject.to_postmark(source, :deep => true)).to eq(target)
      end
    end

    it 'leaves CamelCase keys untouched' do
      expect(subject.to_postmark('ReplyTo' => 'alice@example.com')).to eq('ReplyTo' => 'alice@example.com')
    end
  end

  describe ".to_ruby" do
    let(:source) do
      {
        'LevelOne' => {
          'LevelTwo' => {
            'LevelThree' => [{ 'ArrayItem' => 1 }]
          }
        }
      }
    end

    describe 'default behaviour' do
      let(:target) do
        {
          :level_one => {
            'LevelTwo' => {
              'LevelThree' => [{ 'ArrayItem' => 1 }]
            }
          }
        }
      end

      it 'does not convert nested elements' do
        expect(subject.to_ruby(source)).to eq(target)
      end
    end

    describe 'deep conversion' do
      let(:target) do
        {
          :level_one => {
            :level_two => {
              :level_three => [{ :array_item => 1 }]
            }
          }
        }
      end

      it 'converts nested elements when requested' do
        expect(subject.to_ruby(source, :deep => true)).to eq(target)
      end
    end

    describe 'compatibility mode' do
      let(:target) do
        {
          :level_one => {
            'LevelTwo' => {
              'LevelThree' => [{ 'ArrayItem' => 1 }]
            }
          },
          'LevelOne' => {
            'LevelTwo' => {
              'LevelThree' => [{ 'ArrayItem' => 1 }]
            }
          }
        }
      end

      it 'preserves the original structure' do
        expect(subject.to_ruby(source, :compatible => true)).to eq target
      end
    end

    it 'leaves symbol keys untouched' do
      expect(subject.to_ruby(:reply_to => 'alice@example.com')).to eq(:reply_to => 'alice@example.com')
    end
  end
end