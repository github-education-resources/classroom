class GroupAssignmentsController < ApplicationController
  before_action :ensure_logged_in
  before_action :set_organization
  before_action :set_group_assignment, except: [:new, :create]
  before_action :set_groupings,        except: [:show]

  rescue_from GitHub::Error,     with: :error
  rescue_from GitHub::Forbidden, with: :deny_access
  rescue_from GitHub::NotFound,  with: :not_found

  def new
    @group_assignment = GroupAssignment.new
  end

  def create
    @group_assignment = GroupAssignment.new(new_group_assignment_params)

    if @group_assignment.save
      CreateGroupingJob.perform_later(@group_assignment, new_grouping_params)
      CreateGroupAssignmentInvitationJob.perform_later(@group_assignment)

      flash[:success] = "\"#{@group_assignment.title}\" has been created!"
      redirect_to organization_group_assignment_path(@organization, @group_assignment)
    else
      render :new
    end
  end

  def show
  end

  private

  def deny_access
    flash[:error] = 'You are not authorized to perform this action'
    redirect_to_root
  end

  def error
    flash[:error] = exception.message
    redirect_to :back
  end

  def new_group_assignment_params
    params
      .require(:group_assignment)
      .permit(:title, :public_repo, :grouping_id)
      .merge(creator: current_user,
             organization_id: params[:organization_id],
             starter_code_repo_id: starter_code_repository_id(params[:repo_name]))
  end

  def new_grouping_params
    params
      .require(:grouping)
      .permit(:title)
      .merge(organization_id: new_group_assignment_params[:organization_id])
  end

  def not_found
    flash[:error] = 'We could not find the repository'
    redirect_to :back
  end

  def set_groupings
    @groupings = @organization.groupings.map { |group| [group.title, group.id] }
  end

  def set_group_assignment
    @group_assignment = GroupAssignment.find(params[:id])
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
