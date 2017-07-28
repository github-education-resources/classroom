# frozen_string_literal: true

class RosterEntriesController < ApplicationController
  include OrganizationAuthorization

  before_action :set_roster_entry, :set_assignment, :set_assignment_repo

  layout false

  def show
    if @assignment_repo
      render partial: "roster_entries/assignment_repos/linked_accepted"
    elsif @roster_entry.user
      render partial: "roster_entries/assignment_repos/linked_not_accepted"
    else
      render partial: "roster_entries/assignment_repos/not_in_classroom"
    end
  end

  private

  def set_assignment
    @assignment = if params[:assignment_id]
                    Assignment.find_by!(slug: params[:assignment_id])
                  else
                    GroupAssignment.find_by!(slug: params[:group_assignment_id])
                  end
  rescue ActiveRecord::ActiveRecordError
    not_found
  end

  def set_roster_entry
    @roster_entry = RosterEntry.find(params[:roster_entry_id])
  rescue ActiveRecord::ActiveRecordError
    not_found
  end

  def set_assignment_repo
    @assignment_repo = @assignment.repos.select do |repo|
      if @assignment.is_a? Assignment
        repo.user == @roster_entry.user
      else
        repo.repo_accesses.map(&:user).include? @roster_entry.user
      end
    end.first
  end
end
