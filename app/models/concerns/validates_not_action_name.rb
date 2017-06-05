# frozen_string_literal: true

module ValidatesNotActionName
  extend ActiveSupport::Concern

  included do
    def self.validates_not_action_name(field)
      validates field, exclusion: { in: %w[new edit],
                                    message: 'should not be a reserved action name' }
    end
  end
end
