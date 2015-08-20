class AssignmentsController < ApplicationController
  before_action :set_organization
  before_action :set_assignment, except: [:new, :create]

  rescue_from GitHub::Error, GitHub::Forbidden, GitHub::NotFound, with: :error

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
  end

  private

  def error
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
    @assignment = Assignment.find(params[:id])
  end

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def starter_code_repository_id(repo_name)
    return unless repo_name.present?
    sanitized_repo_name = repo_name.gsub(/\s+/, '')
    github_repository   = GitHubRepository.new(current_user.github_client, nil)
    github_repository.repository(sanitized_repo_name).id
  end
end
