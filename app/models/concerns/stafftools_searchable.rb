# frozen_string_literal: true

module StafftoolsSearchable
  extend ActiveSupport::Concern
  include PgSearch

  class_methods do
    def define_pg_search(columns:)
      pg_search_scope(
        :search,
        against: columns,
        using: {
          tsearch: {
            dictionary: "english"
          }
        }
      )
    end
  end
end
