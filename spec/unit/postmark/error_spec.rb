require 'spec_helper'

describe(Postmark::Error) do
  it {is_expected.to be_a(StandardError)}
end

describe(Postmark::HttpClientError) do
  it {is_expected.to be_a(Postmark::Error)}
  it {expect(subject.retry?).to be true}
end

describe(Postmark::HttpServerError) do
  it {is_expected.to be_a(Postmark::Error)}

  describe '.build' do
    context 'picks an appropriate subclass for code' do
      subject {Postmark::HttpServerError.build(code, Postmark::Json.encode({}))}

      context '401' do
        let(:code) {'401'}

        it {is_expected.to be_a(Postmark::InvalidApiKeyError)}
        its(:status_code) {is_expected.to eq 401}
      end

      context '422' do
        let(:code) {'422'}

        it {is_expected.to be_a(Postmark::ApiInputError)}
        its(:status_code) {is_expected.to eq 422}
      end

      context '500' do
        let(:code) {'500'}

        it {is_expected.to be_a(Postmark::InternalServerError)}
        its(:status_code) {is_expected.to eq 500}
      end

      context 'others' do
        let(:code) {'999'}

        it {is_expected.to be_a(Postmark::UnexpectedHttpResponseError)}
        its(:status_code) {is_expected.to eq code.to_i}
      end
    end
  end

  describe '#retry?' do
    it 'is true for 5XX status codes' do
      (500...600).each do |code|
        expect(Postmark::HttpServerError.new(code).retry?).to be true
      end
    end

    it 'is false for other codes except 5XX' do
      [200, 300, 400].each do |code|
        expect(Postmark::HttpServerError.new(code).retry?).to be false
      end
    end
  end

  describe '#message ' do
    it 'uses "Message" field on postmark response if available' do
      data = {'Message' => 'Postmark error message'}
      error = Postmark::HttpServerError.new(502, Postmark::Json.encode(data), data)
      expect(error.message).to eq data['Message']
    end

    it 'falls back to a message generated from status code' do
      error = Postmark::HttpServerError.new(502, '<html>')
      expect(error.message).to match(/The Postmark API responded with HTTP status \d+/)
    end
  end
end

describe(Postmark::ApiInputError) do
  describe '.build' do
    context 'picks an appropriate subclass for error code' do
      let(:response) {{'ErrorCode' => code}}

      subject do
        Postmark::ApiInputError.build(Postmark::Json.encode(response), response)
      end

      shared_examples_for 'api input error' do
        its(:status_code) {is_expected.to eq 422}
        it {expect(subject.retry?).to be false}
        it {is_expected.to be_a(Postmark::ApiInputError)}
        it {is_expected.to be_a(Postmark::HttpServerError)}
      end

      context '406' do
        let(:code) {Postmark::ApiInputError::INACTIVE_RECIPIENT}

        it {is_expected.to be_a(Postmark::InactiveRecipientError)}
        it_behaves_like 'api input error'
      end

      context '300' do
        let(:code) {Postmark::ApiInputError::INVALID_EMAIL_REQUEST}

        it {is_expected.to be_a(Postmark::InvalidEmailRequestError)}
        it_behaves_like 'api input error'
      end

      context 'others' do
        let(:code) {'9999'}

        it_behaves_like 'api input error'
      end
    end
  end
end

describe Postmark::InvalidTemplateError do
  subject(:error) {Postmark::InvalidTemplateError.new(:foo => 'bar')}

  it 'is created with a response' do
    expect(error.message).to start_with('Failed to render the template.')
    expect(error.postmark_response).to eq(:foo => 'bar')
  end
end

describe(Postmark::TimeoutError) do
  it {is_expected.to be_a(Postmark::Error)}
  it {expect(subject.retry?).to be true}
end

describe(Postmark::UnknownMessageType) do
  it 'exists for backward compatibility' do
    is_expected.to be_a(Postmark::Error)
  end
end

describe(Postmark::InvalidApiKeyError) do
  it {is_expected.to be_a(Postmark::Error)}
end

describe(Postmark::InternalServerError) do
  it {is_expected.to be_a(Postmark::Error)}
end

describe(Postmark::UnexpectedHttpResponseError) do
  it {is_expected.to be_a(Postmark::Error)}
end

describe(Postmark::MailAdapterError) do
  it {is_expected.to be_a(Postmark::Error)}
end

describe(Postmark::InvalidEmailRequestError) do
  describe '.new' do
    let(:response) {{'Message' => message}}

    subject do
      Postmark::InvalidEmailRequestError.new(
        Postmark::ApiInputError::INVALID_EMAIL_REQUEST, Postmark::Json.encode(response), response)
    end

    let(:message) do
      "Error parsing 'To': Illegal email address 'johne.xample.com'. It must contain the '@' symbol."
    end

    it 'body is set' do
      expect(subject.body).to eq(Postmark::Json.encode(response))
    end

    it 'parsed body is set' do
      expect(subject.parsed_body).to eq(response)
    end

    it 'error code is set' do
      expect(subject.error_code).to eq(Postmark::ApiInputError::INVALID_EMAIL_REQUEST)
    end
  end
end

describe(Postmark::InactiveRecipientError) do
  describe '.parse_recipients' do
    let(:recipients) do
      %w(nothing@postmarkapp.com noth.ing+2@postmarkapp.com noth.ing+2-1@postmarkapp.com)
    end

    subject {Postmark::InactiveRecipientError.parse_recipients(message)}

    context '1/1 inactive' do
      let(:message) do
        all_recipients_inactive_message(recipients[0])
      end

      it {is_expected.to eq(recipients.take(1))}
    end

    context 'i/n inactive, n > 1, i < n' do
      let(:message) do
        some_recipients_inactive_message(recipients[0...2].join(', '))
      end

      it {is_expected.to eq(recipients.take(2))}
    end

    context 'n/n inactive, n > 1' do
      let(:message) do
        all_recipients_inactive_message(recipients.join(', '))
      end

      it {is_expected.to eq(recipients)}
    end

    context 'unknown error format' do
      let(:message) {recipients.join(', ')}

      it {is_expected.to eq([])}
    end
  end

  describe '.new' do
    let(:address) {'user@example.org'}
    let(:response) {{'Message' => message}}

    subject do
      Postmark::InactiveRecipientError.new(
          Postmark::ApiInputError::INACTIVE_RECIPIENT,
          Postmark::Json.encode(response),
          response)
    end

    let(:message) do
      all_recipients_inactive_message(address)
    end

    it 'parses recipients from json payload' do
      expect(subject.recipients).to eq([address])
    end

    it 'body is set' do
      expect(subject.body).to eq(Postmark::Json.encode(response))
    end

    it 'parsed body is set' do
      expect(subject.parsed_body).to eq(response)
    end

    it 'error code is set' do
      expect(subject.error_code).to eq(Postmark::ApiInputError::INACTIVE_RECIPIENT)
    end
  end

  def some_recipients_inactive_message(addresses)
   "Message OK, but will not deliver to these inactive addresses: #{addresses}."
  end

  def all_recipients_inactive_message(addresses)
    "You tried to send to recipient(s) that have been marked as inactive. Found inactive addresses: #{addresses}. " \
    "Inactive recipients are ones that have generated a hard bounce, a spam complaint, or a manual suppression."
  end
end

describe(Postmark::DeliveryError) do
  it 'is an alias to Error for backwards compatibility' do
    expect(subject.class).to eq(Postmark::Error)
  end
end

describe(Postmark::InvalidMessageError) do
  it 'is an alias to Error for backwards compatibility' do
    expect(subject.class).to eq(Postmark::ApiInputError)
  end
end

describe(Postmark::UnknownError) do
  it 'is an alias for backwards compatibility' do
    expect(subject.class).to eq(Postmark::UnexpectedHttpResponseError)
  end
end

describe(Postmark::InvalidEmailAddressError) do
  it 'is an alias for backwards compatibility' do
    expect(subject.class).to eq(Postmark::InvalidEmailRequestError)
  end
end
