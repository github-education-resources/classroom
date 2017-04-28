# frozen_string_literal: true

class GroupsController < ApplicationController
  include OrganizationAuthorization

  before_action :ensure_team_management_flipper_is_enabled
  before_action :set_member, only: %i[add_membership remove_membership]

  def add_membership
    repo_access = RepoAccess.find_by(user: @user, organization: @organization)

    if repo_access.present?
      group.repo_accesses << repo_access
      head :no_content
    else
      render json: {
        message: "User isn't a member of this classroom."
      }, status: 422
    end
  end

  def remove_membership
    repo_access = RepoAccess.find_by(user: @user, organization: @organization)

    if repo_access.present?
      group.repo_accesses.delete(repo_access)
      head :no_content
    else
      render json: {
        message: "User isn't a member of this classroom."
      }, status: 422
    end
  end

  private

  def grouping
    @grouping ||= Grouping.find_by!(slug: params[:grouping_id])
  end
  helper_method :grouping

  def group
    @group ||= Group.includes(:repo_accesses).find_by!(slug: params[:id])
  end
  helper_method :group

  def set_member
    @user = User.find_by!(id: params[:user_id])
  end
end
