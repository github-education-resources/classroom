class GroupAssignmentsController < ApplicationController
  include OrganizationAuthorization
  include StarterCode

  before_action :set_group_assignment, except: [:new, :create]
  before_action :set_groupings,        except: [:show]

  decorates_assigned :organization
  decorates_assigned :group_assignment

  rescue_from GitHub::Error,               with: :error
  rescue_from GitHub::Forbidden,           with: :error
  rescue_from GitHub::NotFound,            with: :error

  def new
    @group_assignment = GroupAssignment.new
  end

  def create
    @group_assignment = build_group_assignment

    if @group_assignment.save
      flash[:success] = "\"#{@group_assignment.title}\" has been created!"
      redirect_to organization_group_assignment_path(@organization, @group_assignment)
    else
      render :new
    end
  end

  def show
    @group_assignment_repos = @group_assignment.group_assignment_repos.page(params[:page])
  end

  def edit
  end

  def update
    if @group_assignment.update_attributes(update_group_assignment_params)
      flash[:success] = "Assignment \"#{@group_assignment.title}\" updated"
      redirect_to organization_group_assignment_path(@organization, @group_assignment)
    else
      render :edit
    end
  end

  def destroy
    if @group_assignment.update_attributes(deleted_at: Time.zone.now)
      DestroyResourceJob.perform_later(@group_assignment)

      flash[:success] = "A job has been queued to delete your group assignment \"#{@group_assignment.title}\""
      redirect_to @organization
    else
      render :edit
    end
  end

  private

  def build_group_assignment
    GroupAssignmentService.new(new_group_assignment_params, new_grouping_params).build_group_assignment
  end

  def error(exception)
    flash[:error] = exception.message
    redirect_to :back
  end

  def new_group_assignment_params
    params
      .require(:group_assignment)
      .permit(:title, :public_repo, :grouping_id)
      .merge(creator: current_user,
             organization: @organization,
             starter_code_repo_id: starter_code_repository_id(params[:repo_name]))
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
    @group_assignment = GroupAssignment.friendly.find(params[:id])
  end

  def update_group_assignment_params
    params
      .require(:group_assignment)
      .permit(:title, :public_repo)
      .merge(starter_code_repo_id: starter_code_repository_id(params[:repo_name]))
  end
end
