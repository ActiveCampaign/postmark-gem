require 'spec_helper'

describe 'Accessing server resources using the API' do

  let(:api_client) {
    Postmark::ApiClient.new(ENV['POSTMARK_API_KEY'], :http_open_timeout => 15)
  }
  let(:recipient) { ENV['POSTMARK_CI_RECIPIENT'] }
  let(:message) {
    {
      :from => "tema+ci@wildbit.com",
      :to => recipient,
      :subject => "Mail::Message object",
      :text_body => "Lorem ipsum dolor sit amet, consectetur adipisicing elit, " \
                    "sed do eiusmod tempor incididunt ut labore et dolore " \
                    "magna aliqua."
    }
  }

  context 'Triggers API' do

    let(:unique_token) { rand(36**32).to_s(36) }

    it 'can be used to manage tag triggers via the API' do
      trigger = api_client.create_trigger(:tags,
                                          :match_name => "gemtest_#{unique_token}",
                                          :track_opens => true)
      api_client.update_trigger(:tags,
                                trigger[:id],
                                :match_name => "pre_#{trigger[:match_name]}")
      updated = api_client.get_trigger(:tags, trigger[:id])

      expect(updated[:id]).to eq(trigger[:id])
      expect(updated[:match_name]).not_to eq(trigger[:id])
      expect(api_client.triggers(:tags).map { |t| t[:id] }).to include(trigger[:id])

      api_client.delete_trigger(:tags, trigger[:id])
    end

  end

  context 'Messages API' do

    def with_retries(max_retries = 20, wait_seconds = 3)
      yield
    rescue => e
      retries = retries ? retries + 1 : 1
      if retries < max_retries
        sleep wait_seconds
        retry
      else
        raise e
      end
    end

    it 'is possible to send a message and access its details via the Messages API' do
      response = api_client.deliver(message)
      message = with_retries {
        api_client.get_message(response[:message_id])
      }
      expect(message[:recipients]).to include(recipient)
    end

    it 'is possible to send a message and dump it via the Messages API' do
      response = api_client.deliver(message)
      dump = with_retries {
        api_client.dump_message(response[:message_id])
      }
      expect(dump[:body]).to include('Mail::Message object')
    end

    it 'is possible to send a message and find it via the Messages API' do
      response = api_client.deliver(message)
      expect {
        with_retries {
          messages = api_client.get_messages(:recipient => recipient,
                                  :fromemail => message[:from],
                                  :subject => message[:subject])
          unless messages.map { |m| m[:message_id] }.include?(response[:message_id])
            raise 'Message not found'
          end
        }
      }.not_to raise_error
    end

  end

end