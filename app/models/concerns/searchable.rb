# frozen_string_literal: true

module Searchable
  extend ActiveSupport::Concern

  module ClassMethods
    def filter_by_search(query)
      if search_mode
        send search_mode, query
      else
        all
      end
    end
  end
end
