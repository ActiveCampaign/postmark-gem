module Postmark
  class Bounce

    attr_reader :email, :bounced_at, :type, :details, :name, :id, :server_id, :tag

    def initialize(values = {})
      @id = values["ID"]
      @email = values["Email"]
      @bounced_at = Time.parse(values["BouncedAt"])
      @type = values["Type"]
      @name = values["Name"]
      @details = values["Details"]
      @tag = values["Tag"]
      @dump_available = values["DumpAvailable"]
      @inactive = values["Inactive"]
      @can_activate = values["CanActivate"]
    end

    def inactive?
      !!@inactive
    end

    def can_activate?
      !!@can_activate
    end

    def dump
      Postmark::HttpClient.get("bounces/#{id}/dump")["Body"]
    end

=begin
  def reactivate!
    Bounce.reactivate(self)
  end
=end

    def dump_available?
      !!@dump_available
    end

    class << self
      def find(id)
        Bounce.new(Postmark::HttpClient.get("bounces/#{id}"))
      end

      def all(options = {  })
        options[:count] ||= 30
        options[:offset] ||= 0
        Postmark::HttpClient.get("bounces", options).map { |bounce_json| Bounce.new(bounce_json) }
      end
=begin
      include Postmark::EngineConnection
      def reactivate(bounce)
        put("servers/#{bounce.server_id}/bounces/#{bounce.id}/activate")
      end

      def dump(bounce)
        get("servers/#{bounce.server_id}/bounces/#{bounce.id}/dump")[:body]
      end

      def test_hook_url(url)
        get("bounces/testhook", { :url => url })
      end
=end
    end

  end
end
