require 'spec_helper'

describe 'Accessing server resources using the API' do

  let(:api_client) { Postmark::ApiClient.new(ENV['POSTMARK_API_KEY']) }
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

  context 'Messages API' do

    def with_retries(max_retries = 10, wait_seconds = 3)
      yield
    rescue Postmark::DeliveryError
      retries = retries ? retries + 1 : 1
      if retries < max_retries
        sleep wait_seconds
        retry
      else
        raise
      end
    end

    it 'is possible to send a message and access it via the Messages API' do
      response = api_client.deliver(message)
      message = with_retries {
        api_client.get_message(response[:message_id])
      }
      expect(message[:recipients]).to include(recipient)
      dump = api_client.dump_message(response[:message_id])
      expect(dump[:body]).to include('Mail::Message object')
    end

  end

end