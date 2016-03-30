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

  def new_assignment_params
    params
      .require(:assignment)
      .permit(:title, :public_repo)
      .merge(creator: current_user,
             organization: @organization,
             starter_code_repo_id: starter_code_repo_id_param)
  end

  def set_assignment
    @assignment = @organization.assignments.find_by!(id: params[:id])
  rescue ActiveRecord::RecordNotFound
    @assignment = @organization.assignments.find_by!(slug: params[:id])
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
end
