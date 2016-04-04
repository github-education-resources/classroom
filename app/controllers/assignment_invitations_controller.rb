class AssignmentInvitationsController < ApplicationController
  layout 'layouts/invitations'

  before_action :check_user_not_previous_acceptee, only: [:show]
  before_action :check_repo_name_suffix_not_empty, only: [:accept_invitation]

  def check_repo_name_suffix_not_empty
    return if params[:repo_name_suffix].nil?
    if params[:repo_name_suffix].empty?
      flash[:error] = 'Repository name suffix can not be empty'
      redirect_to :back
    end
  end

  def accept_invitation
    users_assignment_repo = invitation.redeem_for(current_user, params[:repo_name_suffix])
    if users_assignment_repo.present?
      redirect_to successful_invitation_assignment_invitation_path
    else
      flash[:error] = 'An error has occured, please refresh the page and try again.'
      redirect_to :show
    end
  end

  def show
  end

  def successful_invitation
    not_found unless assignment_repo
  end

  private

  def github_repository
    github_repository = GitHubRepository.new(current_user.github_client, nil)
    begin
      repo_name = "#{decorated_organization.login}/#{assignment.slug}-#{decorated_current_user.login}"
      @github_repository ||= github_repository.repository(repo_name)
    rescue GitHub::NotFound
      @github_repository ||= nil
    end
  end
  helper_method :github_repository

  def required_scopes
    %w(user:email)
  end

  def assignment
    @assignment ||= invitation.assignment
  end
  helper_method :assignment

  def assignment_repo
    @assignment_repo ||= AssignmentRepo.find_by(assignment: assignment, user: current_user)
  end
  helper_method :assignment_repo

  def decorated_assignment_repo
    @decorated_assignment_repo ||= assignment_repo.decorate
  end
  helper_method :decorated_assignment_repo

  def decorated_organization
    @decorated_organization ||= organization.decorate
  end
  helper_method :decorated_organization

  def invitation
    @invitation ||= AssignmentInvitation.find_by!(key: params[:id])
  end
  helper_method :invitation

  def organization
    @organization ||= assignment.organization
  end
  helper_method :organization

  def check_user_not_previous_acceptee
    return unless assignment.users.include?(current_user)
    redirect_to successful_invitation_assignment_invitation_path
  end
end
