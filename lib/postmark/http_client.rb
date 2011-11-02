require 'cgi'

module Postmark
  module HttpClient
    EMAIL_REGEX = /[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i

    class << self
      def post(path, data = '')
        handle_response(http.post(url_path(path), data, headers))
      end

      def put(path, data = '')
        handle_response(http.put(url_path(path), data, headers))
      end

      def get(path, query = {})
        handle_response(http.get(url_path(path + to_query_string(query)), headers))
      end

      protected

      def to_query_string(hash)
        return "" if hash.empty?
        "?" + hash.map { |key, value| "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}" }.join("&")
      end

      def protocol
        Postmark.secure ? "https" : "http"
      end

      def url
        URI.parse("#{protocol}://#{Postmark.host}:#{Postmark.port}/")
      end

      def handle_response(response)
        case response.code.to_i
        when 200
          return Postmark::Json.decode(response.body)
        when 401
          raise InvalidApiKeyError, error_message(response.body)
        when 422
          error = InvalidMessageError.new(error_message(response.body))
          error.emails = error_emails(response.body)
          raise error
        when 500
          raise InternalServerError, response.body
        else
          raise UnknownError, response
        end
      end

      def headers
        @headers ||= HEADERS.merge({ "X-Postmark-Server-Token" => Postmark.api_key.to_s })
      end

      def url_path(path)
        Postmark.path_prefix + path
      end

      def http
        @http ||= build_http
      end

      def build_http
        http = Net::HTTP::Proxy(Postmark.proxy_host,
                                Postmark.proxy_port,
                                Postmark.proxy_user,
                                Postmark.proxy_pass).new(url.host, url.port)

        http.read_timeout = Postmark.http_read_timeout
        http.open_timeout = Postmark.http_open_timeout
        http.use_ssl = !!Postmark.secure
        http
      end

      def error_emails(response_body)
        json = Postmark::Json.decode(response_body)
        if json['ErrorCode'] == 406
          json['Message'].scan(EMAIL_REGEX)
        else
          []
        end
      end

      def error_message(response_body)
        Postmark::Json.decode(response_body)["Message"]
      end
    end
  end
end
