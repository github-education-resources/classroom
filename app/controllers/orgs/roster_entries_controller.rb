# frozen_string_literal: true

module Orgs
  class RosterEntriesController < Orgs::Controller
    before_action :ensure_current_assignment
    before_action :ensure_current_roster
    before_action :ensure_current_roster_entry

    helper_method :current_assignment_repo, :current_roster_entry

    layout false

    def show
      if current_assignment_repo
        render partial: "orgs/roster_entries/assignment_repos/linked_accepted",
               locals: { assignment_repo: current_assignment_repo }
      elsif current_roster_entry.user
        render partial: "orgs/roster_entries/assignment_repos/linked_not_accepted"
      else
        render partial: "orgs/roster_entries/assignment_repos/not_in_classroom"
      end
    end

    private

    def current_assignment
      return @current_assignment if defined?(@current_assignment)
      @current_assignment = if params[:assignment_id]
                              current_organization.assignments.find_by(slug: params[:assignment_id])
                            else
                              current_organization.group_assignments.find_by(slug: params[:group_assignment_id])
                            end
    end

    def current_assignment_repo
      return @current_assignment_repo if defined?(@current_assignment_repo)
      return @current_assignment_repo = nil if current_roster_entry.user.nil?
      @current_assignment_repo = find_current_assignment_repo
    end

    def current_roster
      return @current_roster if defined?(@current_roster)
      @current_roster = current_organization.roster
    end

    def current_roster_entry
      return @current_roster_entry if defined?(@current_roster_entry)
      current_roster.roster_entries.find(params[:roster_entry_id])
    end

    def ensure_current_assignment
      not_found if current_assignment.nil?
    end

    def ensure_current_roster
      not_found if current_roster.nil?
    end

    def ensure_current_roster_entry
      not_found if current_roster_entry.nil?
    end

    def find_assignment_repo
      current_assignment.repos.find_by(user: current_roster_entry.user)
    end

    def find_current_assignment_repo
      return find_assignment_repo if current_assignment.is_a?(Assignment)
      find_group_assignment_repo
    end

    def find_group_assignment_repo
      current_assignment.repos.select do |repo|
        repo.repo_accesses.map(&:user).include?(current_roster_entry.user)
      end.first
    end
  end
end
