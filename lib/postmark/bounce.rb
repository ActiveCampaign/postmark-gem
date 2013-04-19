require 'time'

module Postmark
  class Bounce

    attr_reader :email, :bounced_at, :type, :details, :name, :id, :server_id, :tag, :message_id, :subject

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
      @message_id     = values["MessageID"]
      @subject        = values["Subject"]
    end

    def inactive?
      !!@inactive
    end

    def can_activate?
      !!@can_activate
    end

    def dump
      Postmark.api_client.dump_bounce(id)["Body"]
    end

    def activate
      Bounce.new(Postmark.api_client.activate_bounce(id)["Bounce"])
    end

    def dump_available?
      !!@dump_available
    end

    class << self
      def find(id)
        Bounce.new(Postmark.api_client.get_bounce(id))
      end

      def all(options = {})
        options[:count]  ||= 30
        options[:offset] ||= 0
        Postmark.api_client.get_bounces(options)['Bounces'].map do |bounce_json|
          Bounce.new(bounce_json)
        end
      end

      def tags
        Postmark.api_client.get_bounced_tags
      end
    end

  end
end
