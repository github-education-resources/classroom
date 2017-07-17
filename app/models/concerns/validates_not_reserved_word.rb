# frozen_string_literal: true

module ValidatesNotReservedWord
  extend ActiveSupport::Concern

  included do
    def self.validates_not_reserved_word(field)
      validates field, exclusion: {
        in: GitHubClassroom::Blacklist::NAMES,
        message: "is a reserved word"
      }
    end
  end
end
