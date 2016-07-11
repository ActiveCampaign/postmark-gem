require 'time'

module Postmark
  class Bounce

    attr_reader :email, :bounced_at, :type, :description, :details, :name, :id, :server_id, :tag, :message_id, :subject

    def initialize(values = {})
      values = Postmark::HashHelper.to_ruby(values)
      @id = values[:id]
      @email = values[:email]
      @bounced_at = Time.parse(values[:bounced_at])
      @type = values[:type]
      @name = values[:name]
      @description = values[:description]
      @details = values[:details]
      @tag = values[:tag]
      @dump_available = values[:dump_available]
      @inactive = values[:inactive]
      @can_activate = values[:can_activate]
      @message_id = values[:message_id]
      @subject = values[:subject]
    end

    def inactive?
      !!@inactive
    end

    def can_activate?
      !!@can_activate
    end

    def dump
      Postmark.api_client.dump_bounce(id)[:body]
    end

    def activate
      Bounce.new(Postmark.api_client.activate_bounce(id))
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
        Postmark.api_client.get_bounces(options).map do |bounce_json|
          Bounce.new(bounce_json)
        end
      end

      def tags
        Postmark.api_client.get_bounced_tags
      end
    end

  end
end
