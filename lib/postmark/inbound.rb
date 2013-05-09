module Postmark
  module Inbound
    extend self

    def to_ruby_hash(inbound)
      inbound = Json.decode(inbound) if inbound.is_a?(String)
      ret = HashHelper.to_ruby(inbound)
      ret[:from_full] ||= {}
      ret[:to_full] ||= []
      ret[:cc_full] ||= []
      ret[:headers] ||= []
      ret[:attachments] ||= []
      ret[:from_full] = HashHelper.to_ruby(ret[:from_full])
      ret[:to_full] = ret[:to_full].map { |to| HashHelper.to_ruby(to) }
      ret[:cc_full] = ret[:cc_full].map { |cc| HashHelper.to_ruby(cc) }
      ret[:headers] = ret[:headers].map { |h| HashHelper.to_ruby(h) }
      ret[:attachments] = ret[:attachments].map { |a| HashHelper.to_ruby(a) }
      ret
    end
  end
end