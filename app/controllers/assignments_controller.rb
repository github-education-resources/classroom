class AssignmentsController < ApplicationController
  include OrganizationAuthorization
  include StarterCode

  before_action :set_assignment, except: [:new, :create]

  decorates_assigned :organization
  decorates_assigned :assignment

  rescue_from ActiveRecord::RecordInvalid, with: :error
  rescue_from GitHub::Error,               with: :error
  rescue_from GitHub::Forbidden,           with: :error
  rescue_from GitHub::NotFound,            with: :error

  def new
    @assignment = Assignment.new
  end

  def create
    @assignment = Assignment.new(new_assignment_params)

    if @assignment.save
      CreateAssignmentInvitationJob.perform_later(@assignment)

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
      flash[:success] = "A job has been queued to delete your individual assignment \"#{@assignment.title}\""
      redirect_to @organization
    else
      render :edit
    end
  end

  private

  def error(exception)
    flash[:error] = exception.message
    redirect_to :back
  end

  def new_assignment_params
    params
      .require(:assignment)
      .permit(:title, :public_repo)
      .merge(creator: current_user,
             organization: @organization,
             starter_code_repo_id: starter_code_repository_id(params[:repo_name]))
  end

  def set_assignment
    @assignment = Assignment.friendly.find(params[:id])
  end

  def update_assignment_params
    params
      .require(:assignment)
      .permit(:title, :public_repo)
      .merge(starter_code_repo_id: starter_code_repository_id(params[:repo_name]))
  end
end
