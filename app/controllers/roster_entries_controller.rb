# frozen_string_literal: true

class RosterEntriesController < ApplicationController
  include OrganizationAuthorization

  before_action :set_roster_entry, :set_organization, :set_assignment, :set_assignment_repo

  layout false

  def show
    if @assignment_repo
      render "roster_entries/assignment_repos/linked_accepted"
    elsif @roster_entry.user
      render "roster_entries/assignment_repos/linked_not_accepted"
    else
      render "roster_entries/assignment_repos/not_in_classroom"
    end
  end

  private

  def set_assignment
    @assignment = Assignment.find_by!(slug: params[:assignment_id])
  rescue ActiveRecord::ActiveRecordError
    not_found
  end

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_id])
  rescue ActiveRecord::ActiveRecordError
    not_found
  end

  def set_roster_entry
    @roster_entry = RosterEntry.find(params[:roster_entry_id])
  rescue ActiveRecord::ActiveRecordError
    not_found
  end

  def set_assignment_repo
    @assignment_repo = @assignment.repos.select { |repo| repo.user == @roster_entry.user }.first
  end
end
