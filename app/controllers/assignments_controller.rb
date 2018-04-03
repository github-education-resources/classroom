# frozen_string_literal: true

class AssignmentsController < ApplicationController
  include OrganizationAuthorization
  include StarterCode

  before_action :set_assignment, except: %i[new create]
  before_action :set_unlinked_users, only: [:show]

  def new
    @assignment = Assignment.new
  end

  def create
    @assignment = Assignment.new(new_assignment_params)

    @assignment.build_assignment_invitation

    if @assignment.save
      @assignment.deadline&.create_job

      send_create_assignment_statsd_events
      flash[:success] = "\"#{@assignment.title}\" has been created!"
      redirect_to organization_assignment_path(@organization, @assignment)
    else
      render :new
    end
  end

  def show
    if @organization.roster
      @roster_entries = @organization.roster.roster_entries.page(params[:students_page]).order_for_view(@assignment)

      @unlinked_user_repos = AssignmentRepo.where(assignment: @assignment, user: @unlinked_users)
                                           .page(params[:unlinked_accounts_page])
    else
      @assignment_repos = AssignmentRepo.where(assignment: @assignment).page(params[:page])
    end
  end

  def edit; end

  def update
    result = Assignment::Editor.perform(assignment: @assignment, options: update_assignment_params.to_h)
    if result.success?
      flash[:success] = "Assignment \"#{@assignment.title}\" is being updated"
      redirect_to organization_assignment_path(@organization, @assignment)
    else
      @assignment.reload if @assignment.slug.blank?
      render :edit
    end
  end

  def destroy
    if @assignment.update_attributes(deleted_at: Time.zone.now)
      DestroyResourceJob.perform_later(@assignment)

      GitHubClassroom.statsd.increment("exercise.destroy")

      flash[:success] = "\"#{@assignment.title}\" is being deleted"
      redirect_to @organization
    else
      render :edit
    end
  end

  private

  def new_assignment_params
    params
      .require(:assignment)
      .permit(:title, :slug, :public_repo, :students_are_repo_admins, :invitations_enabled)
      .merge(creator: current_user,
             organization: @organization,
             starter_code_repo_id: starter_code_repo_id_param,
             deadline: deadline_param)
  end

  # An unlinked user in the context of an assignment is a user who:
  # - Is a user on the assignment
  # - Is not on the organization roster
  def set_unlinked_users
    return unless @organization.roster

    assignment_users = @assignment.users

    roster_entry_user_ids = @organization.roster.roster_entries.pluck(:user_id)
    roster_entry_users = User.where(id: roster_entry_user_ids)

    @unlinked_users = assignment_users - roster_entry_users
  end

  def set_assignment
    @assignment = @organization.assignments.includes(:assignment_invitation).find_by!(slug: params[:id])
  end

  def deadline_param
    return if params[:assignment][:deadline].blank?

    Deadline::Factory.build_from_string(deadline_at: params[:assignment][:deadline])
  end

  def starter_code_repo_id_param
    if params[:repo_id].present?
      validate_starter_code_repository_id(params[:repo_id])
    else
      starter_code_repository_id(params[:repo_name])
    end
  end

  def update_assignment_params
    params
      .require(:assignment)
      .permit(:title, :slug, :public_repo, :students_are_repo_admins, :deadline, :invitations_enabled)
      .merge(starter_code_repo_id: starter_code_repo_id_param)
  end

  def send_create_assignment_statsd_events
    GitHubClassroom.statsd.increment("exercise.create")
    GitHubClassroom.statsd.increment("deadline.create") if @assignment.deadline
  end
end
