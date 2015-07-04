class AssignmentsController < ApplicationController
  before_action :redirect_to_root,           unless: :logged_in?
  before_action :set_organization
  before_action :ensure_organization_admin
  before_action :set_assignment,             except: [:new, :create]

  rescue_from GitHub::Error,     with: :error
  rescue_from GitHub::Forbidden, with: :deny_access

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
  end

  def deny_access
    flash[:error] = 'You are not authorized to perform this action'
    redirect_to_root
  end

  def ensure_organization_admin
    github_organization = GitHubOrganization.new(current_user.github_client, @organization.github_id)

    login = github_organization.login
    github_organization.authorization_on_github_organization?(login)
  end

  def new_assignment_params
    params
      .require(:assignment)
      .permit(:title, :public_repo)
      .merge(organization_id: params[:organization_id])
  end

  def set_assignment
    @assignment = Assignment.find(params[:id])
  end

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end
end
