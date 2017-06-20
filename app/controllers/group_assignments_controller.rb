# frozen_string_literal: true

class GroupAssignmentsController < ApplicationController
  include OrganizationAuthorization
  include StarterCode

  before_action :set_group_assignment, except: %i[new create]
  before_action :set_groupings,        except: [:show]

  before_action :authorize_grouping_access, only: %i[create update]

  def new
    @group_assignment = GroupAssignment.new
  end

  def create
    @group_assignment = build_group_assignment

    if @group_assignment.save
      @group_assignment.deadline&.create_job

      flash[:success] = "\"#{@group_assignment.title}\" has been created!"
      redirect_to organization_group_assignment_path(@organization, @group_assignment)
    else
      render :new
    end
  end

  def show
    @group_assignment_repos = GroupAssignmentRepo.where(group_assignment: @group_assignment).page(params[:page])
  end

  def edit; end

  def update
    result = Assignment::Editor.perform(assignment: @group_assignment, options: update_group_assignment_params.to_h)
    if result.success?
      flash[:success] = "Assignment \"#{@group_assignment.title}\" is being updated"
      redirect_to organization_group_assignment_path(@organization, @group_assignment)
    else
      @group_assignment.reload if @group_assignment.slug.blank?
      render :edit
    end
  end

  def destroy
    if @group_assignment.update_attributes(deleted_at: Time.zone.now)
      DestroyResourceJob.perform_later(@group_assignment)

      flash[:success] = "\"#{@group_assignment.title}\" is being deleted"
      redirect_to @organization
    else
      render :edit
    end
  end

  private

  def student_identifier_types
    @student_identifier_types ||= @organization.student_identifier_types.select(:name, :id).map do |student_identifier|
      [student_identifier.name, student_identifier.id]
    end
  end
  helper_method :student_identifier_types

  def authorize_grouping_access
    grouping_id = new_group_assignment_params[:grouping_id]

    return if grouping_id.blank?
    return if @organization.groupings.find_by(id: grouping_id)

    raise NotAuthorized, 'You are not permitted to select this set of teams'
  end

  def build_group_assignment
    GroupAssignmentService.new(new_group_assignment_params, new_grouping_params).build_group_assignment
  end

  def new_group_assignment_params
    params
      .require(:group_assignment)
      .permit(:title, :slug, :public_repo, :grouping_id, :max_members, :students_are_repo_admins)
      .merge(creator: current_user,
             organization: @organization,
             starter_code_repo_id: starter_code_repo_id_param,
             student_identifier_type: student_identifier_type_param,
             deadline: deadline_param)
  end

  def new_grouping_params
    params
      .require(:grouping)
      .permit(:title)
      .merge(organization: @organization)
  end

  def set_groupings
    @groupings = @organization.groupings.map { |group| [group.title, group.id] }
  end

  def set_group_assignment
    @group_assignment = @organization
                        .group_assignments
                        .includes(:group_assignment_invitation)
                        .find_by!(slug: params[:id])
  end

  def deadline_param
    return unless deadlines_enabled? && params[:group_assignment][:deadline].present?

    Deadline::Factory.build_from_string(deadline_at: params[:group_assignment][:deadline])
  end

  def starter_code_repo_id_param
    if params[:repo_id].present?
      validate_starter_code_repository_id(params[:repo_id])
    else
      starter_code_repository_id(params[:repo_name])
    end
  end

  def student_identifier_type_param
    return unless params.key?(:student_identifier_type)
    StudentIdentifierType.find_by(id: student_identifier_type_params[:id], organization: @organization)
  end

  def update_group_assignment_params
    params
      .require(:group_assignment)
      .permit(:title, :slug, :public_repo, :max_members, :students_are_repo_admins, :deadline)
      .merge(starter_code_repo_id: starter_code_repo_id_param, student_identifier_type: student_identifier_type_param)
  end

  def student_identifier_type_params
    params
      .require(:student_identifier_type)
      .permit(:id)
  end
end
