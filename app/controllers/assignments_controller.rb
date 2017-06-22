# frozen_string_literal: true

class AssignmentsController < ApplicationController
  include OrganizationAuthorization
  include StarterCode

  before_action :set_assignment, except: %i[new create]

  def new
    @assignment = Assignment.new
  end

  def create
    @assignment = Assignment.new(new_assignment_params)

    @assignment.build_assignment_invitation

    if @assignment.save
      @assignment.deadline&.create_job

      flash[:success] = "\"#{@assignment.title}\" has been created!"
      redirect_to organization_assignment_path(@organization, @assignment)
    else
      render :new
    end
  end

  def show
    @assignment_repos = AssignmentRepo.where(assignment: @assignment).page(params[:page])
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
      flash[:success] = "\"#{@assignment.title}\" is being deleted"
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

  def new_assignment_params
    params
      .require(:assignment)
      .permit(:title, :slug, :public_repo, :students_are_repo_admins)
      .merge(creator: current_user,
             organization: @organization,
             starter_code_repo_id: starter_code_repo_id_param,
             student_identifier_type: student_identifier_type_param,
             deadline: deadline_param)
  end

  def set_assignment
    @assignment = @organization.assignments.includes(:assignment_invitation).find_by!(slug: params[:id])
  end

  def deadline_param
    return unless deadlines_enabled? && params[:assignment][:deadline].present?

    Deadline::Factory.build_from_string(deadline_at: params[:assignment][:deadline]) if deadlines_enabled?
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

  def update_assignment_params
    params
      .require(:assignment)
      .permit(:title, :slug, :public_repo, :students_are_repo_admins, :deadline)
      .merge(starter_code_repo_id: starter_code_repo_id_param, student_identifier_type: student_identifier_type_param)
  end

  def student_identifier_type_params
    params
      .require(:student_identifier_type)
      .permit(:id)
  end
end
