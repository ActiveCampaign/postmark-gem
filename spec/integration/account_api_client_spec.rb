require 'spec_helper'

describe 'Account API client usage' do

  subject { Postmark::AccountApiClient.new(ENV['POSTMARK_ACCOUNT_API_KEY'],
                                           :http_open_timeout => 15,
                                           :http_read_timeout => 15) }
  let(:unique_token) { rand(36**32).to_s(36) }
  let(:unique_from_email) { ENV['POSTMARK_CI_SENDER'].gsub(/(\+.+)?@/, "+#{unique_token}@") }

  it 'can be used to manage senders' do
    new_sender = nil

    # create & count
    new_sender = subject.create_sender(:name => 'Integration Test',
                                       :from_email => unique_from_email)
    expect(subject.get_senders_count).to be > 0

    # get
    expect(subject.get_sender(new_sender[:id])[:id]).to eq(new_sender[:id])

    # list
    senders = subject.get_senders(:count => 50)
    expect(senders.map { |s| s[:id] }).to include(new_sender[:id])

    # collection
    expect(subject.senders.map { |s| s[:id] }).to include(new_sender[:id])

    # update
    updated_sender = subject.update_sender(new_sender[:id], :name => 'New Name')
    expect(updated_sender[:name]).to eq('New Name')
    expect(updated_sender[:id]).to eq(new_sender[:id])

    # spf
    expect(subject.verified_sender_spf?(new_sender[:id])).to be_true

    # resend
    expect { subject.resend_sender_confirmation(new_sender[:id]) }.not_to raise_error

    # dkim
    expect { subject.request_new_sender_dkim(new_sender[:id]) }.
        to raise_error(Postmark::InvalidMessageError,
                       'This DKIM is already being renewed.')

    # delete
    expect { subject.delete_sender(new_sender[:id]) }.not_to raise_error
  end

  it 'can be used to manage servers' do
    new_server = nil

    # create & count
    new_server = subject.create_server(:name => "server-#{unique_token}",
                                       :color => 'red')
    expect(subject.get_servers_count).to be > 0

    # get
    expect(subject.get_server(new_server[:id])[:id]).to eq(new_server[:id])

    # list
    servers = subject.get_servers(:count => 50)
    expect(servers.map { |s| s[:id] }).to include(new_server[:id])

    # collection
    expect(subject.servers.map { |s| s[:id] }).to include(new_server[:id])

    # update
    updated_server = subject.update_server(new_server[:id], :color => 'blue')
    expect(updated_server[:color]).to eq('blue')
    expect(updated_server[:id]).to eq(new_server[:id])

    # delete
    expect { subject.delete_server(new_server[:id]) }.not_to raise_error
  end

end