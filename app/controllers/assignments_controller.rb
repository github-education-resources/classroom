# frozen_string_literal: true
class AssignmentsController < ApplicationController
  include OrganizationAuthorization
  include StarterCode

  before_action :set_assignment, except: [:new, :create]

  decorates_assigned :organization
  decorates_assigned :assignment

  def new
    @assignment = Assignment.new
  end

  def create
    @assignment = Assignment.new(new_assignment_params)
    @assignment.build_assignment_invitation

    if @assignment.save
      flash[:success] = "\"#{@assignment.title}\" has been created!"
      redirect_to organization_assignment_path(@organization, @assignment)
    else
      render :new
    end
  end

  def show
    @assignment_repos = @assignment.assignment_repos.page(params[:page])
  end

  def edit
  end

  def update
    @assignment.student_identifier_type = student_identifier_type_param

    if @assignment.update_attributes(update_assignment_params)
      flash[:success] = "Assignment \"#{@assignment.title}\" updated"
      redirect_to organization_assignment_path(@organization, @assignment)
    else
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
    @student_identifier_types ||= @organization.student_identifier_types.map do |student_identifier|
      [student_identifier.name, student_identifier.id]
    end
  end
  helper_method :student_identifier_types

  def new_assignment_params
    params
      .require(:assignment)
      .permit(:title, :public_repo)
      .merge(creator: current_user,
             organization: @organization,
             starter_code_repo_id: starter_code_repo_id_param)
  end

  def set_assignment
    @assignment = @organization.assignments.find_by!(slug: params[:id])
  end

  def student_identifier_type_param
    unless params.key?(:student_identifier_type) && params.key?(:student_identifier_type)
      return nil
    end
    StudentIdentifierType.find_by(id: student_identifier_params[:id], organization: @organization)
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
      .permit(:title, :public_repo)
      .merge(starter_code_repo_id: starter_code_repo_id_param)
  end

  def student_identifier_params
    params
      .require(:student_identifier_type)
      .permit(:id, :name, :description)
  end
end
