module Postmark

  class AccountApiClient < Client

    def initialize(api_key, options = {})
      options[:auth_header_name] = 'X-Postmark-Account-Token'
      super
    end

    def get_senders(options = {})
      options[:offset] ||= 0
      options[:count] ||= 10
      format_response http_client.get('senders', options)['SenderSignatures']
    end
    alias_method :get_signatures, :get_senders

    def get_sender(id)
      format_response http_client.get("senders/#{id.to_i}")
    end
    alias_method :get_signature, :get_sender

    def create_sender(attributes = {})
      data = serialize(HashHelper.to_postmark(attributes))

      format_response http_client.post('senders', data)
    end
    alias_method :create_signature, :create_sender

    def update_sender(id, attributes = {})
      data = serialize(HashHelper.to_postmark(attributes))

      format_response http_client.put("senders/#{id.to_i}", data)
    end
    alias_method :update_signature, :update_sender

    def resend_sender_confirmation(id)
      format_response http_client.post("senders/#{id.to_i}/resend")
    end
    alias_method :resend_signature_confirmation, :resend_sender_confirmation

    def verified_sender_spf?(id)
      !!http_client.post("senders/#{id.to_i}/verifyspf")['SPFVerified']
    end
    alias_method :verified_signature_spf?, :verified_sender_spf?

    def request_new_sender_dkim(id)
      format_response http_client.post("senders/#{id.to_i}/requestnewdkim")
    end
    alias_method :request_new_signature_dkim, :request_new_sender_dkim

    def delete_sender(id)
      format_response http_client.delete("senders/#{id.to_i}")
    end
    alias_method :delete_signature, :delete_sender

    def get_servers(options = {})
      options[:offset] ||= 0
      options[:count] ||= 10
      format_response http_client.get('servers', options)['Servers']
    end

    def get_server(id)
      format_response http_client.get("servers/#{id.to_i}")
    end

    def create_server(attributes = {})
      data = serialize(HashHelper.to_postmark(attributes))
      format_response http_client.post('servers', data)
    end

    def update_server(id, attributes = {})
      data = serialize(HashHelper.to_postmark(attributes))
      format_response http_client.put("servers/#{id.to_i}", data)
    end

    def delete_server(id)
      format_response http_client.delete("servers/#{id.to_i}")
    end

  end

end