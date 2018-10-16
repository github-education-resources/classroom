# frozen_string_literal: true

# This module contains all ElasticSearch indices and their assocated models.
module ESIndices
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
  private_constant :MODEL_SYMBOL_TO_INDEX_SYMBOL

  # Returns all ElasticSearch indexed models.
  def self.models
    MODEL_SYMBOL_TO_INDEX_SYMBOL.keys.map { |model_symbol| model_symbol.to_s.constantize }
  end

  # Reaturns all ElasticSearch Chewy indices.
  def self.indices
    MODEL_SYMBOL_TO_INDEX_SYMBOL.values.map { |model_symbol| model_symbol.to_s.constantize }
  end
end
