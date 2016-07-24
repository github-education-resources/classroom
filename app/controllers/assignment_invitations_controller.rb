# frozen_string_literal: true
class AssignmentInvitationsController < ApplicationController
  layout 'layouts/invitations'

  before_action :check_user_not_previous_acceptee, only: [:show]
  before_action :ensure_github_repo_exists, only: [:successful_invitation]

  def accept_invitation
    create_assignment_repo { redirect_to successful_invitation_assignment_invitation_path }
  end

  def show
  end

  def successful_invitation
  end

  private

  def required_scopes
    Classroom::Scopes::ASSIGNMENT_STUDENT
  end

  def assignment
    @assignment ||= invitation.assignment
  end
  helper_method :assignment

  def assignment_repo
    @assignment_repo ||= AssignmentRepo.find_by(assignment: assignment, user: current_user)
  end
  helper_method :assignment_repo

  def invitation
    @invitation ||= AssignmentInvitation.find_by!(key: params[:id])
  end
  helper_method :invitation

  def organization
    @organization ||= assignment.organization
  end
  helper_method :organization

  def create_assignment_repo
    users_assignment_repo = invitation.redeem_for(current_user)

    if users_assignment_repo.present?
      yield if block_given?
    else
      flash[:error] = 'An error has occured, please refresh the page and try again.'
      redirect_to :show
    end
  end

  def check_user_not_previous_acceptee
    return unless assignment.users.include?(current_user)
    redirect_to successful_invitation_assignment_invitation_path
  end

  def ensure_github_repo_exists
    return not_found unless assignment_repo
    return if assignment_repo.github_repository.present?

    assignment_repo.destroy
    @assignment_repo = nil
    create_assignment_repo
  end
end
