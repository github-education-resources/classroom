# frozen_string_literal: true

module ElasticSearch

  def self.models
    MODEL_SYMBOL_TO_INDEX.keys.map { |model_symbol| model_symbol.to_s.constantize }
  end

  def self.indices
    MODEL_SYMBOL_TO_INDEX.values
  end

  private

  MODEL_SYMBOL_TO_INDEX = {
    Assignment: AssignmentIndex,
    AssignmentInvitation: AssignmentInvitationIndex,
    AssignmentRepo: AssignmentRepoIndex,
    GroupAssignment: GroupAssignmentIndex,
    GroupAssignmentInvitation: GroupAssignmentInvitationIndex,
    GroupAssignmentRepo: GroupAssignmentRepoIndex,
    Group: GroupIndex,
    Grouping: GroupingIndex,
    Organization: OrganizationIndex,
    RepoAccess: RepoAccessIndex,
    User: UserIndex,
  }.freeze
end
