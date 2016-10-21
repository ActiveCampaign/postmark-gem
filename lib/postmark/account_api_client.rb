module Postmark

  class AccountApiClient < Client

    def initialize(api_token, options = {})
      options[:auth_header_name] = 'X-Postmark-Account-Token'
      super
    end

    def senders(options = {})
      find_each('senders', 'SenderSignatures', options)
    end
    alias_method :signatures, :senders

    def get_senders(options = {})
      load_batch('senders', 'SenderSignatures', options).last
    end
    alias_method :get_signatures, :get_senders

    def get_senders_count(options = {})
      get_resource_count('senders', options)
    end
    alias_method :get_signatures_count, :get_senders_count

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

    def domains(options = {})
      find_each('domains', 'Domains', options)
    end

    def get_domains(options = {})
      load_batch('domains', 'Domains', options).last
    end

    def get_domains_count(options = {})
      get_resource_count('domains', options)
    end

    def get_domain(id)
      format_response http_client.get("domains/#{id.to_i}")
    end

    def create_domain(attributes = {})
      data = serialize(HashHelper.to_postmark(attributes))

      format_response http_client.post('domains', data)
    end

    def update_domain(id, attributes = {})
      data = serialize(HashHelper.to_postmark(attributes))

      format_response http_client.put("domains/#{id.to_i}", data)
    end

    def verified_domain_spf?(id)
      !!http_client.post("domains/#{id.to_i}/verifyspf")['SPFVerified']
    end

    def rotate_domain_dkim(id)
      format_response http_client.post("domains/#{id.to_i}/rotatedkim")
    end

    def delete_domain(id)
      format_response http_client.delete("domains/#{id.to_i}")
    end

    def servers(options = {})
      find_each('servers', 'Servers', options)
    end

    def get_servers(options = {})
      load_batch('servers', 'Servers', options).last
    end

    def get_servers_count(options = {})
      get_resource_count('servers', options)
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
