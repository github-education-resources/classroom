# frozen_string_literal: true

module ESIndices
  def self.models
    MODEL_SYMBOL_TO_INDEX_SYMBOL.keys.map { |model_symbol| model_symbol.to_s.constantize }
  end

  def self.indices
    MODEL_SYMBOL_TO_INDEX_SYMBOL.values.map { |model_symbol| model_symbol.to_s.constantize }
  end

  private

  MODEL_SYMBOL_TO_INDEX_SYMBOL = {
    Assignment:                :AssignmentIndex,
    AssignmentInvitation:      :AssignmentInvitationIndex,
    AssignmentRepo:            :AssignmentRepoIndex,
    GroupAssignment:           :GroupAssignmentIndex,
    GroupAssignmentInvitation: :GroupAssignmentInvitationIndex,
    GroupAssignmentRepo:       :GroupAssignmentRepoIndex,
    Group:                     :GroupIndex,
    Grouping:                  :GroupingIndex,
    Organization:              :OrganizationIndex,
    RepoAccess:                :RepoAccessIndex,
    User:                      :UserIndex
  }.freeze
end
