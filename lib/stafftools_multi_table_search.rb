# frozen_string_literal: true

class StafftoolsMultiTableSearch
  class << self
    TABLES = [
      Assignment,
      AssignmentInvitation,
      AssignmentRepo,
      GroupAssignment,
      GroupAssignmentInvitation,
      GroupAssignmentRepo,
      Group,
      Grouping,
      Organization,
      RepoAccess,
      User
    ]

    def search(query)
      results = {}

      TABLES.each do |table|
        results[table.to_s.pluralize] = table.search(query).first(20).to_a
      end

      results
    end
  end
end
