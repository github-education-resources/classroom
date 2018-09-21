# frozen_string_literal: true

module Stafftools
  class ResourcesController < StafftoolsController
    class StafftoolsRequest < Chewy::Search::Request
      include Chewy::Search::Pagination::Kaminari
    end

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
    ].freeze

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
      @resources = StafftoolsRequest.new(*ALL_INDICIES)
        .query(match_phrase_prefix(params[:query]))
        .order(_type: :asc)
        .page(params[:page])
        .per(20)
    end

    def match_phrase_prefix(query)
      searchable_fields = %w[github_id github_repo_id github_team_id id key login name slug title uid]
      { bool: { should: searchable_fields.map { |field| { "match_phrase_prefix" => { field => query } } } } }
    end
  end
end
