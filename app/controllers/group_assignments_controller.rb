# frozen_string_literal: true

# rubocop:disable ClassLength
class GroupAssignmentsController < ApplicationController
  include OrganizationAuthorization
  include StarterCode

  before_action :set_group_assignment,      except: %i[new create]
  before_action :set_groupings,             except: %i[show]
  before_action :set_pagination_key,        only: %i[create show]
  before_action :set_filter_options,        only: %i[show]
  before_action :authorize_grouping_access, only: %i[create update]

  def new
    @group_assignment = GroupAssignment.new
  end

  def create
    @group_assignment = build_group_assignment

    if @group_assignment.save
      @group_assignment.deadline&.create_job

      GitHubClassroom.statsd.increment("group_exercise.create")
      GitHubClassroom.statsd.increment("deadline.create") if @group_assignment.deadline

      flash[:success] = "\"#{@group_assignment.title}\" has been created!"
      redirect_to organization_group_assignment_path(@organization, @group_assignment)
    else
      render :new
    end
  end

  # rubocop:disable AbcSize
  # rubocop:disable MethodLength
  def show
    matching_groups = @group_assignment.grouping.groups
    if search_assignments_enabled? && @query.present?
      matching_groups = matching_groups.where("title ILIKE ?", "%#{@query}%")
    end

    @group_assignment_repos = GroupAssignmentRepo
      .where(group_assignment: @group_assignment, group_id: matching_groups.ids)
      .order_by_sort_mode(@current_sort_mode)
      .order(:id)
      .page(params[@pagination_key])

    if @organization.roster
      @students_not_on_team = @organization.roster.roster_entries
        .students_not_on_team(@group_assignment)
        .order(:id)
        .page(params[:students_page])
    end

    respond_to do |format|
      format.html
      format.js do
        not_found unless search_assignments_enabled?
        render "group_assignments/filter_repos.js.erb", format: :js
      end
    end
  end
  # rubocop:enable MethodLength
  # rubocop:enable AbcSize

  def edit; end

  def update
    result = Assignment::Editor.perform(assignment: @group_assignment, options: update_group_assignment_params.to_h)
    if result.success?
      flash[:success] = "Assignment \"#{@group_assignment.title}\" is being updated"
      redirect_to organization_group_assignment_path(@organization, @group_assignment)
    else
      @group_assignment.reload if @group_assignment.slug.blank?
      render :edit
    end
  end

  def destroy
    if @group_assignment.update_attributes(deleted_at: Time.zone.now)
      DestroyResourceJob.perform_later(@group_assignment)

      GitHubClassroom.statsd.increment("group_exercise.destroy")

      flash[:success] = "\"#{@group_assignment.title}\" is being deleted"
      redirect_to @organization
    else
      render :edit
    end
  end

  def assistant
    code_param = current_user.api_token
    url_param = CGI.escape(organization_group_assignment_url)

    redirect_to "x-github-classroom://?assignment_url=#{url_param}&code=#{code_param}"
  end

  private

  def authorize_grouping_access
    grouping_id = new_group_assignment_params[:grouping_id]

    return if grouping_id.blank?
    return if @organization.groupings.find_by(id: grouping_id)

    raise NotAuthorized, "You are not permitted to select this set of teams"
  end

  def build_group_assignment
    GroupAssignmentService.new(new_group_assignment_params, new_grouping_params).build_group_assignment
  end

  # rubocop:disable MethodLength
  def new_group_assignment_params
    params
      .require(:group_assignment)
      .permit(
        :title,
        :slug,
        :public_repo,
        :grouping_id,
        :max_members,
        :students_are_repo_admins,
        :invitations_enabled,
        :max_teams,
        :template_repos_enabled
      )
      .merge(
        creator: current_user,
        organization: @organization,
        starter_code_repo_id: starter_code_repo_id_param,
        deadline: deadline_param
      )
  end
  # rubocop:enable MethodLength

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
    @group_assignment = @organization
      .group_assignments
      .includes(:group_assignment_invitation)
      .find_by!(slug: params[:id])
  end

  def set_filter_options
    @assignment_sort_modes = GroupAssignmentRepo.sort_modes

    @current_sort_mode = params[:sort_assignment_repos_by] || @assignment_sort_modes.keys.first
    @query = params[:query]

    @assignment_sort_modes_links = @assignment_sort_modes.keys.map do |mode|
      organization_group_assignment_path(
        sort_assignment_repos_by: mode,
        query: @query
      )
    end

    @current_sort_mode = params[:sort_assignment_repos_by] || @assignment_sort_modes.keys.first
  end

  def set_pagination_key
    @pagination_key = @organization.roster ? :teams_page : :page
  end

  def deadline_param
    return if params[:group_assignment][:deadline].blank?

    Deadline::Factory.build_from_string(deadline_at: params[:group_assignment][:deadline])
  end

  def starter_code_repo_id_param
    if params[:repo_id].present?
      validate_starter_code_repository_id(params[:repo_id])
    else
      starter_code_repository_id(params[:repo_name])
    end
  end

  # rubocop:disable MethodLength
  def update_group_assignment_params
    params
      .require(:group_assignment)
      .permit(
        :title,
        :slug,
        :public_repo,
        :max_members,
        :students_are_repo_admins,
        :deadline,
        :invitations_enabled,
        :max_teams,
        :template_repos_enabled
      )
      .merge(starter_code_repo_id: starter_code_repo_id_param)
  end
  # rubocop:enable MethodLength
end
# rubocop:enable ClassLength
