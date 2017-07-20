# frozen_string_literal: true

class RosterEntriesController < ApplicationController
  before_action :set_roster_entry, :set_organization, :set_assignment, :ensure_authorized

  layout false

  def show; end

  private

  def ensure_authorized
    not_found unless @organization.users.include? current_user
  end

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
end
