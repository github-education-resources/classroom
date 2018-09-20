# frozen_string_literal: true

module Stafftools
  class ResourcesController < StafftoolsController
    ALL_INDICIES = [
      AssignmentIndex,
      AssignmentInvitationIndex,
      AssignmentRepoIndex,
      DeadlineIndex,
      GroupAssignmentIndex,
      GroupAssignmentInvitationIndex,
      GroupAssignmentRepoIndex,
      GroupIndex,
      GroupingIndex,
      OrganizationIndex,
      RepoAccessIndex,
      UserIndex
    ]

    before_action :set_resources

    def index; end

    def search
      respond_to do |format|
        format.html { render partial: "stafftools/resources/search_results", locals: { resources: @resources } }
      end
    end

    private

    def set_resources
      return @resources = nil if params[:query].blank?
      @resources = query
        .order(_type: :asc)
        .page(params[:page])
        .per(20)
    end

    def query
      @query ||= combined_indices_query
    end

    def combined_indices_query
      queries = ALL_INDICIES.map { |index| index.query(match_phrase_prefix(params[:query])) }
      queries
        .drop(1)
        .reduce(queries.first) { |combined_query, query| combined_query.merge(query) }
    end

    def match_phrase_prefix(query)
      searchable_fields = %w[github_id github_repo_id github_team_id id key login name slug title uid]
      { bool: { should: searchable_fields.map { |field| { "match_phrase_prefix" => { field => query } } } } }
    end
  end
end
