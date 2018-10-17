# frozen_string_literal: true

module GraphQLNode
  extend ActiveSupport::Concern

  def global_relay_id
    Base64.strict_encode64(["0", self.class.name, ":", id.to_s].join)
  end
end
