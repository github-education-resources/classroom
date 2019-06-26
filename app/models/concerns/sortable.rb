# frozen_string_literal: true

module Sortable
  extend ActiveSupport::Concern

  module ClassMethods
    def order_by_sort_mode(mode, context = nil)
      sort_mode_scope = sort_modes[mode]
      if sort_mode_scope
        send sort_mode_scope, context
      else
        all
      end
    end
  end
end
