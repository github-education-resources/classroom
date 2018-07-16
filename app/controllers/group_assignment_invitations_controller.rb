# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class GroupAssignmentInvitationsController < ApplicationController
  include InvitationsControllerMethods
  include RepoSetup

  layout "layouts/invitations"

  before_action :check_group_not_previous_acceptee,    only: [:show]
  before_action :check_user_not_group_member,          only: [:show]
  before_action :check_should_redirect_to_roster_page, only: [:show]

  before_action :authorize_group_access, only: [:accept_invitation]

  before_action :ensure_authorized_repo_setup, only: %i[setup setup_progress]
  before_action :ensure_github_repo_exists,    only: %i[setup setup_progress successful_invitation]

  def show
    @groups = invitation.groups.map { |group| [group.title, group.id] }
  end

  def setup; end

  def setup_progress
    perform_setup(group_assignment_repo, classroom_config) if configurable_submission?

    render json: setup_status(group_assignment_repo)
  end

  def accept; end

  def accept_assignment
    create_group_assignment_repo do
      if group_assignment_repo.starter_code_repo_id
        redirect_to setup_group_assignment_invitation_path
      else
        redirect_to successful_invitation_group_assignment_invitation_path
      end
    end
  end

  def accept_invitation
    selected_group       = Group.find_by(id: group_params[:id])
    selected_group_title = group_params[:title]

    create_group_assignment_repo(selected_group: selected_group, new_group_title: selected_group_title) do
      if group_assignment_repo.starter_code_repo_id
        redirect_to setup_group_assignment_invitation_path
      else
        redirect_to successful_invitation_group_assignment_invitation_path
      end
    end
  end

  def successful_invitation; end

  def join_roster
    super

    redirect_to group_assignment_invitation_url(invitation)
  rescue ActiveRecord::ActiveRecordError
    flash[:error] = "An error occured, please try again!"
  end

  private

  def required_scopes
    GitHubClassroom::Scopes::GROUP_ASSIGNMENT_STUDENT
  end

  def authorize_group_access
    group_id = group_params[:id]

    return if group_id.blank?
    group = Group.find(group_id)
    validate_max_members_not_exceeded!(group)
    return if group_assignment.grouping.groups.find_by(id: group_id)

    GitHubClassroom.statsd.increment("group_exercise_invitation.fail")
    raise NotAuthorized, "You are not permitted to select this team"
  end

  # rubocop:disable Metrics/AbcSize
  def validate_max_members_not_exceeded!(group)
    return unless group.present? && group_assignment.present? && group_assignment.max_members.present?
    return unless group.repo_accesses.count >= group_assignment.max_members

    GitHubClassroom.statsd.increment("group_exercise_invitation.fail")
    raise NotAuthorized, "This team has reached its maximum member limit of #{group_assignment.max_members}."
  end
  # rubocop:enable Metrics/AbcSize

  def group
    repo_access = current_user.repo_accesses.find_by(organization: organization)
    return unless repo_access.present? && repo_access.groups.present?

    @group ||= repo_access.groups.find_by(grouping: group_assignment.grouping)
  end
  helper_method :group

  def create_group_assignment_repo(selected_group: group, new_group_title: nil)
    if !invitation.enabled?
      flash[:error] = "Invitations for this assignment have been disabled."
      redirect_to group_assignment_invitation_path
    else
      users_group_assignment_repo = invitation.redeem_for(current_user, selected_group, new_group_title)

      if users_group_assignment_repo.present?
        GitHubClassroom.statsd.increment("group_exercise_invitation.accept")
        yield if block_given?
      else
        GitHubClassroom.statsd.increment("group_exercise_invitation.fail")

        flash[:error] = "An error has occurred, please refresh the page and try again."
        redirect_to group_assignment_invitation_path
      end
    end
  end

  def group_assignment
    @group_assignment ||= invitation.group_assignment
  end
  helper_method :group_assignment

  def group_assignment_repo
    @group_assignment_repo ||= GroupAssignmentRepo.find_by(group_assignment: group_assignment, group: group)
  end
  helper_method :group_assignment_repo

  def group_params
    params
      .require(:group)
      .permit(:id, :title)
  end

  def invitation
    @invitation ||= GroupAssignmentInvitation
                    .includes(group_assignment: :group_assignment_repos)
                    .find_by!(key: params[:id])
  end
  helper_method :invitation

  def organization
    @organization ||= group_assignment.organization
  end
  helper_method :organization

  def classroom_config
    starter_code_repo_id = group_assignment_repo.starter_code_repo_id

    return unless starter_code_repo_id

    client       = group_assignment_repo.creator.github_client
    starter_repo = GitHubRepository.new(client, starter_code_repo_id)

    @classroom_config ||= ClassroomConfig.new(starter_repo)
  end

  def configurable_submission?
    repo             = group_assignment_repo.github_repository
    classroom_branch = repo.branch_present?("github-classroom")
    repo.imported? && classroom_branch && group_assignment_repo.not_configured?
  end

  def check_group_not_previous_acceptee
    return unless group.present? && group_assignment_repo.present?

    if repo_setup_enabled? && setup_status(group_assignment_repo)[:status] != :complete
      redirect_to setup_group_assignment_invitation_path
    else
      redirect_to successful_invitation_group_assignment_invitation_path
    end
  end

  def check_user_not_group_member
    return if group.blank?
    redirect_to accept_group_assignment_invitation_path
  end

  def ensure_authorized_repo_setup
    redirect_to successful_invitation_group_assignment_invitation_path unless repo_setup_enabled?
  end

  def ensure_github_repo_exists
    return not_found unless group_assignment_repo
    return if group_assignment_repo
              .github_repository
              .present?(headers: GitHub::APIHeaders.no_cache_no_store)

    group = group_assignment_repo.group

    group_assignment_repo.destroy
    @group_assignment_repo = nil
    create_group_assignment_repo(selected_group: group)
  end
end
# rubocop:enable Metrics/ClassLength
