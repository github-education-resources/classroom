# frozen_string_literal: true

class AssignmentInvitationsController < ApplicationController
  include InvitationsControllerMethods
  include SetupRepo

  before_action :check_user_not_previous_acceptee, only: [:show]
  before_action :ensure_submission_repository_exists, only: [:success]
  before_action :check_authorized_repo_setup, only: %i[setup setup_progress]

  def accept
    create_submission do
      redirect_to setup_assignment_invitation_path
    end
  end

  def setup
    starter_code_repo_id = current_submission.assignment.starter_code_repo_id
    redirect_to success_assignment_invitation_path unless starter_code_repo_id
  end

  def setup_progress
    perform_setup(current_submission, classroom_config) if configurable_submission?

    render json: setup_status(current_submission.github_repository, classroom_config)
  end

  def show; end

  def success; end

  private

  def ensure_submission_repository_exists
    return not_found unless current_submission
    return if current_submission
              .github_repository
              .present?(headers: GitHub::APIHeaders.no_cache_no_store)

    current_submission.destroy
    remove_instance_variable(:@current_submission)

    create_submission
  end

  def check_user_not_previous_acceptee
    return if current_submission.nil?
    redirect_to success_assignment_invitation_path
  end

  def check_authorized_repo_setup
    redirect_to success_assignment_invitation_path unless repo_setup_enabled?
  end

  def classroom_config
    starter_code_repo_id = current_submission.assignment.starter_code_repo_id
    client               = current_submission.creator.github_client

    starter_repo         = GitHubRepository.new(client, starter_code_repo_id)
    ClassroomConfig.new(starter_repo)
  end

  def configurable_submission?
    repo = current_submission.github_repository
    configurable = classroom_config.configurable? repo
    repo.import_progress[:status] == 'complete' && configurable && params[:configure]
  end

  def create_submission
    result = current_invitation.redeem_for(current_user)

    if result.success?
      yield if block_given?
    else
      flash[:error] = result.error
      redirect_to assignment_invitation_path(current_invitation)
    end
  end

  def current_submission
    @current_submission ||= AssignmentRepo.find_by(assignment: current_assignment, user: current_user)
  end

  def current_invitation
    @current_invitation ||= AssignmentInvitation.find_by!(key: params[:id])
  end

  def required_scopes
    GitHubClassroom::Scopes::ASSIGNMENT_STUDENT
  end
end
