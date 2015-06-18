class AssignmentsController < ApplicationController
  before_action :redirect_to_root,           unless: :logged_in?
  before_action :ensure_organization_admin

  before_action :set_assignment,             except: [:new, :create]
  before_action :set_organization,           only: [:new, :create]

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

  def ensure_organization_admin
    github_id = Organization.find(params[:organization_id]).github_id

    return if current_user.github_client.organization_admin?(github_id)
    render text: 'Unauthorized', status: 401
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
