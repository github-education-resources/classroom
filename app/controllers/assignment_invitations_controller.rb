# frozen_string_literal: true

class AssignmentInvitationsController < ApplicationController
  class InvalidStatusForRouteError < StandardError; end

  include InvitationsControllerMethods
  include RepoSetup

  before_action :route_based_on_status, only: %i[show setup success]
  before_action :check_should_redirect_to_roster_page, only: :show
  before_action :ensure_submission_repository_exists, only: :success

  # rubocop:disable MethodLength
  # rubocop:disable AbcSize
  def accept
    result = current_invitation.redeem_for(current_user)
    case result.status
    when :success
      current_invitation_status.completed! if current_invitation_status.unaccepted?
      GitHubClassroom.statsd.increment("exercise_invitation.accept")
    when :pending
      current_invitation_status.accepted!
      GitHubClassroom.statsd.increment("exercise_invitation.accept")
    when :failed
      GitHubClassroom.statsd.increment("exercise_invitation.fail")
      current_invitation_status.unaccepted!
      flash[:error] = result.error
    end
    route_based_on_status
  end
  # rubocop:enable MethodLength
  # rubocop:enable AbcSize

  def setup; end

  # rubocop:disable MethodLength
  # rubocop:disable AbcSize
  # rubocop:disable CyclomaticComplexity
  # rubocop:disable PerceivedComplexity
  def create_repo
    job_started = false
    if current_invitation_status.accepted? || current_invitation_status.errored?
      assignment_repo = AssignmentRepo.find_by(assignment: current_assignment, user: current_user)
      assignment_repo&.destroy if assignment_repo&.github_repository&.empty?
      if current_invitation_status.errored_creating_repo?
        GitHubClassroom.statsd.increment("exercise_repo.create.retry")
      elsif current_invitation_status.errored_importing_starter_code?
        GitHubClassroom.statsd.increment("exercise_repo.import.retry")
      end
      current_invitation_status.waiting!
      if unified_repo_creators_enabled?
        CreateGitHubRepositoryNewJob.perform_later(current_assignment, current_user, retries: 3)
      else
        AssignmentRepo::CreateGitHubRepositoryJob.perform_later(current_assignment, current_user, retries: 3)
      end

      job_started = true
    end
    render json: {
      job_started: job_started,
      status: current_invitation_status.status,
      repo_url: current_submission&.github_repository&.html_url
    }
  end
  # rubocop:enable MethodLength
  # rubocop:enable AbcSize
  # rubocop:enable CyclomaticComplexity
  # rubocop:enable PerceivedComplexity

  def progress
    render json: {
      status: current_invitation_status.status,
      repo_url: current_submission&.github_repository&.html_url
    }
  end

  def show; end

  def success; end

  def join_roster
    super

    redirect_to assignment_invitation_url(current_invitation)
  rescue ActiveRecord::ActiveRecordError
    flash[:error] = "An error occured, please try again!"
  end

  private

  def ensure_submission_repository_exists
    github_repo_exists = current_submission &&
      current_submission
        .github_repository
        .present?(headers: GitHub::APIHeaders.no_cache_no_store)
    return if github_repo_exists

    current_submission&.destroy
    @current_submission = nil
    current_invitation_status.accepted!

    redirect_to setup_assignment_invitation_path
  end

  # rubocop:disable AbcSize
  # rubocop:disable CyclomaticComplexity
  def route_based_on_status
    case current_invitation_status.status
    when "unaccepted"
      redirect_to assignment_invitation_path(current_invitation) if action_name != "show"
    when "completed"
      redirect_to success_assignment_invitation_path if action_name != "success"
    when *(InviteStatus::ERRORED_STATUSES + InviteStatus::SETUP_STATUSES)
      redirect_to setup_assignment_invitation_path if action_name != "setup"
    else
      raise InvalidStatusForRouteError, "No route registered for status: #{current_invitation_status.status}"
    end
  end
  # rubocop:enable AbcSize
  # rubocop:enable CyclomaticComplexity

  def create_submission
    result = current_invitation.redeem_for(current_user)

    if result.success?
      yield if block_given?
    else
      GitHubClassroom.statsd.increment("exercise_invitation.fail")

      flash[:error] = result.error
      redirect_to assignment_invitation_path(current_invitation)
    end
  end

  def assignment
    @assignment ||= current_invitation.assignment
  end
  helper_method :assignment

  def current_submission
    @current_submission ||= AssignmentRepo.find_by(assignment: current_assignment, user: current_user)
  end

  def current_invitation
    @current_invitation ||= AssignmentInvitation.find_by!(key: params[:id])
  end

  def current_invitation_status
    @current_invitation_status ||= current_invitation.status(current_user)
  end

  def required_scopes
    GitHubClassroom::Scopes::ASSIGNMENT_STUDENT
  end
end
