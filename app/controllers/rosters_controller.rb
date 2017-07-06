# frozen_string_literal: true

class RostersController < ApplicationController
  before_action :ensure_student_identifier_flipper_is_enabled, :set_organization
  before_action :set_roster, only: [:show]

  def show; end

  def new
    @roster = Roster.new
  end

  def create
    @roster = Roster.new(identifier_name: params[:identifier_name])
    @roster.save!

    add_identifiers_to_roster

    @organization.roster = @roster
    @organization.save!

    flash[:success] = 'Your classroom roster has been saved! Manage it HERE' # TODO: ADD LINK TO MANAGE PAGE

    redirect_to organization_path(@organization)
  rescue ActiveRecord::RecordInvalid
    render :new
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:id])
  end

  def set_roster
    @roster = @organization.roster
  end

  def add_identifiers_to_roster
    identifiers = split_identifiers(params[:identifiers])
    identifiers.each do |identifier|
      @roster.roster_entries << RosterEntry.create(identifier: identifier)
    end
  end

  def split_identifiers(raw_identifiers_string)
    raw_identifiers_string.split("\r\n").reject(&:empty?).uniq
  end
end
