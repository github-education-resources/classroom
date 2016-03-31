class GroupAssignmentsController < ApplicationController
  include OrganizationAuthorization
  include StarterCode

  before_action :set_group_assignment, except: [:new, :create]
  before_action :set_groupings,        except: [:show]

  before_action :authorize_grouping_access, only: [:create, :update]

  decorates_assigned :organization
  decorates_assigned :group_assignment

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

      flash[:success] = "\"#{@group_assignment.title}\" is being deleted"
      redirect_to @organization
    else
      render :edit
    end
  end

  private

  def authorize_grouping_access
    grouping_id = new_group_assignment_params[:grouping_id]

    return unless grouping_id.present?
    return if @organization.groupings.find_by(id: grouping_id)

    raise NotAuthorized, 'You are not permitted to select this group of teams'
  end

  def build_group_assignment
    GroupAssignmentService.new(new_group_assignment_params, new_grouping_params).build_group_assignment
  end

  def new_group_assignment_params
    params
      .require(:group_assignment)
      .permit(:title, :public_repo, :grouping_id, :max_members)
      .merge(creator: current_user,
             organization: @organization,
             starter_code_repo_id: starter_code_repo_id_param)
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
    @group_assignment = @organization.group_assignments.find_by!(id: params[:id])
  rescue ActiveRecord::RecordNotFound
    @group_assignment = @organization.group_assignments.find_by!(slug: params[:id])
    redirect_to action: params[:action], id: @group_assignment.id, organization_id: params[:organization_id],
                status: 301
  end

  def starter_code_repo_id_param
    if params[:repo_id].present?
      validate_starter_code_repository_id(params[:repo_id])
    else
      starter_code_repository_id(params[:repo_name])
    end
  end

  def update_group_assignment_params
    params
      .require(:group_assignment)
      .permit(:title, :public_repo, :max_members)
      .merge(starter_code_repo_id: starter_code_repo_id_param)
  end
end
