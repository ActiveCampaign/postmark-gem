require 'spec_helper'

describe Postmark::HashHelper do
  describe ".to_postmark" do
    context 'single level hash objects to convert' do
      let(:source) { { :from => "support@postmarkapp.com", :reply_to => "contact@wildbit.com" } }
      let(:target) { { "From" => "support@postmarkapp.com", "ReplyTo" => "contact@wildbit.com" } }

      it 'converts Hash keys to Postmark format' do
        expect(subject.to_postmark(source)).to eq target
      end

      it 'acts idempotentely' do
        subject.to_postmark(target)
        expect(subject.to_postmark(target)).to eq target
      end
    end

    context 'complex multi level hash objects to convert' do
      it 'convert Hash keys to Postmark format - one sub level hash' do
        source = { :id => 'custom-id',
                   :name => 'Some Stream Name 3',
                   :message_stream_type => 'Broadcasts',
                   :subscription_management_configuration => { :unsubscribe_handling_type => 'Custom' } }

        target = { 'Id' => 'custom-id',
                   'Name' => 'Some Stream Name 3',
                   'MessageStreamType' => 'Broadcasts',
                   'SubscriptionManagementConfiguration' => { 'UnsubscribeHandlingType' => 'Custom' } }

        expect(subject.to_postmark(source)).to eq target
      end

      context 'convert multiple sub level hash' do
        let(:ruby_formatted_hash) {
          { :id => 'custom-id',
            :top => {
              :level_one => {
                :level_two => {
                  :level_three => [
                    { :one_level_three_type => 'Value1' },
                    { :second_level_three_type => 'Value2'}
                  ]
                }
              }
            }
          }
        }

        let(:postmark_formatted_hash) {
          { 'Id' => 'custom-id',
            'Top' => {
              'LevelOne' => {
                'LevelTwo' => {
                  'LevelThree' => [
                    {'OneLevelThreeType' => 'Value1'},
                    {'SecondLevelThreeType' => 'Value2'}
                  ]
                }
              }
            }
          }
        }

        it 'default conversion' do
          expect(subject.to_postmark(ruby_formatted_hash)).to eq postmark_formatted_hash
        end

        it 'deep conversion off' do
          target = { 'Id' => 'custom-id',
                      'Top' => {
                      :level_one => {
                        :level_two => {
                          :level_three => [
                              { :one_level_three_type => 'Value1' },
                              { :second_level_three_type => 'Value2'}
                          ] }
                        }
                      }
                    }

          expect(subject.to_postmark(ruby_formatted_hash, :deep_conversion => false)).to eq target
        end

        it 'skip key' do
          target = { 'Id' => 'custom-id',
                     'Top' => {
                       'LevelOne' => {
                         :level_two => {
                           :level_three => [
                             { :one_level_three_type => 'Value1' },
                             { :second_level_three_type => 'Value2'}
                           ]
                         }
                       }
                     }
          }

          expect(subject.to_postmark(ruby_formatted_hash, keys_to_skip: [:level_one])).to eq target
        end
      end
    end
  end

  describe ".to_ruby" do
    context 'single level hash objects to convert' do
      let(:source) { { "From" => "support@postmarkapp.com", "ReplyTo" => "contact@wildbit.com" } }
      let(:target) { { :from => "support@postmarkapp.com", :reply_to => "contact@wildbit.com" } }

      it 'converts Hash keys to Ruby format' do
        expect(subject.to_ruby(source)).to eq target
      end

      it 'has compatible mode' do
        expect(subject.to_ruby(source, true)).to eq target.merge(source)
      end

      it 'acts idempotentely' do
        subject.to_ruby(target)
        expect(subject.to_ruby(target)).to eq target
      end
    end

    context 'complex multi level hash objects to convert' do
      it 'convert Hash keys to Ruby format - one sub level hash' do
        target = { :id => 'custom-id',
                   :name => 'Some Stream Name 3',
                   :message_stream_type => 'Broadcasts',
                   :subscription_management_configuration => { :unsubscribe_handling_type => 'Custom' } }

        source = { 'Id' => 'custom-id',
                   'Name' => 'Some Stream Name 3',
                   'MessageStreamType' => 'Broadcasts',
                   'SubscriptionManagementConfiguration' => { 'UnsubscribeHandlingType' => 'Custom' } }

        expect(subject.to_ruby(source)).to eq target
      end

      it 'convert Hash keys to Ruby format - multiple sub level hash' do
        target = { :id => 'custom-id',
                   :top => {
                     :level_one => {
                       :level_two => {
                         :level_three => [
                           { :one_level_three_type => 'Value1' },
                           { :second_level_three_type => 'Value2'}
                         ]
                       }
                     }
                   }
        }

        source = { 'Id' => 'custom-id',
                   'Top' => {
                     'LevelOne' => {
                       'LevelTwo' => {
                         'LevelThree' => [
                           {'OneLevelThreeType' => 'Value1'},
                           {'SecondLevelThreeType' => 'Value2'}
                         ]
                       }
                     }
                   }
        }

        expect(subject.to_ruby(source)).to eq target
      end

      it 'convert Hash keys to Ruby format - multiple sub level hash - deep conversion off' do
        target = { :id => 'custom-id',
                   :top => {
                     :level_one => {
                       :level_two => {
                         :level_three => [
                           { :one_level_three_type => 'Value1' },
                           { :second_level_three_type => 'Value2'}
                         ]
                       }
                     }
                   }
        }

        source = { 'Id' => 'custom-id',
                   'Top' => {
                     :level_one => {
                       :level_two => {
                         :level_three => [
                           { :one_level_three_type => 'Value1' },
                           { :second_level_three_type => 'Value2'}
                         ]
                       }
                     }
                   }
        }

        expect(subject.to_ruby(source)).to eq target
      end
    end
  end
end