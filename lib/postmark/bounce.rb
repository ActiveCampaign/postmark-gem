require 'time'

module Postmark
  class Bounce

    attr_reader :email, :bounced_at, :type, :details, :name, :id, :server_id, :tag

    def initialize(values = {})
      @id             = values["ID"]
      @email          = values["Email"]
      @bounced_at     = Time.parse(values["BouncedAt"])
      @type           = values["Type"]
      @name           = values["Name"]
      @details        = values["Details"]
      @tag            = values["Tag"]
      @dump_available = values["DumpAvailable"]
      @inactive       = values["Inactive"]
      @can_activate   = values["CanActivate"]
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

    def activate
      Bounce.new(Postmark::HttpClient.put("bounces/#{id}/activate")["Bounce"])
    end

    def dump_available?
      !!@dump_available
    end

    class << self
      def find(id)
        Bounce.new(Postmark::HttpClient.get("bounces/#{id}"))
      end

      def all(options = {})
        options[:count]  ||= 30
        options[:offset] ||= 0
        Postmark::HttpClient.get("bounces", options)['Bounces'].map { |bounce_json| Bounce.new(bounce_json) }
      end

      def tags
        Postmark::HttpClient.get("bounces/tags")
      end
    end

  end
end
