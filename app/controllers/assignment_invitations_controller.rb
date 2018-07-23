# frozen_string_literal: true

class AssignmentInvitationsController < ApplicationController
  include InvitationsControllerMethods
  include RepoSetup

  before_action :check_user_not_previous_acceptee, :check_should_redirect_to_roster_page, only: [:show]
  before_action :ensure_submission_repository_exists, only: :success

  # rubocop:disable MethodLength
  # rubocop:disable AbcSize
  def accept
    if import_resiliency_enabled?
      result = current_invitation.redeem_for(current_user, import_resiliency: import_resiliency_enabled?)
      case result.status
      when :success
        GitHubClassroom.statsd.increment("v2_exercise_invitation.accept")
        if current_invitation_status.completed?
          redirect_to success_assignment_invitation_path
        else
          redirect_to setupv2_assignment_invitation_path
        end
      when :pending
        GitHubClassroom.statsd.increment("v2_exercise_invitation.accept")
        redirect_to setupv2_assignment_invitation_path
      when :error
        GitHubClassroom.statsd.increment("v2_exercise_invitation.fail")
        current_invitation_status.errored_creating_repo!

        flash[:error] = result.error
        redirect_to assignment_invitation_path(current_invitation)
      end
    else
      create_submission do
        GitHubClassroom.statsd.increment("exercise_invitation.accept")
        redirect_to success_assignment_invitation_path
      end
    end
  end
  # rubocop:enable MethodLength
  # rubocop:enable AbcSize

  def setupv2
    not_found unless import_resiliency_enabled?
  end

  # rubocop:disable MethodLength
  # rubocop:disable AbcSize
  def create_repo
    if import_resiliency_enabled?
      job_started = false
      if current_invitation_status.accepted? || current_invitation_status.errored?
        assignment_repo = AssignmentRepo.find_by(assignment: current_assignment, user: current_user)
        assignment_repo&.destroy if assignment_repo&.github_repository&.empty?
        current_invitation_status.waiting!
        AssignmentRepo::CreateGitHubRepositoryJob.perform_later(current_assignment, current_user)
        job_started = true
      end
      render json: {
        job_started: job_started,
        status: current_invitation_status.status
      }
    else
      render status: 404, json: { error: "Not found" }
    end
  end
  # rubocop:enable MethodLength
  # rubocop:enable AbcSize

  def progress
    if import_resiliency_enabled?
      render json: { status: current_invitation_status.status }
    else
      render status: 404, json: { error: "Not found" }
    end
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

  # rubocop:disable MethodLength
  def ensure_submission_repository_exists
    return not_found unless current_submission
    return if current_submission
              .github_repository
              .present?(headers: GitHub::APIHeaders.no_cache_no_store)

    current_submission.destroy
    remove_instance_variable(:@current_submission)

    if import_resiliency_enabled?
      redirect_to setupv2_assignment_invitation_path
    else
      create_submission
    end
  end
  # rubocop:enable MethodLength

  def check_user_not_previous_acceptee
    return if current_submission.nil?
    return unless current_invitation&.completed?
    redirect_to success_assignment_invitation_path
  end

  def classroom_config
    starter_code_repo_id = current_submission.starter_code_repo_id
    client               = current_submission.creator.github_client

    starter_repo         = GitHubRepository.new(client, starter_code_repo_id)
    ClassroomConfig.new(starter_repo)
  end

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

  def current_submission
    @current_submission ||= AssignmentRepo.find_by(assignment: current_assignment, user: current_user)
  end

  def current_invitation
    @current_invitation ||= AssignmentInvitation.find_by!(key: params[:id])
  end

  def current_invitation_status
    current_invitation.status(current_user)
  end

  def required_scopes
    GitHubClassroom::Scopes::ASSIGNMENT_STUDENT
  end
end
