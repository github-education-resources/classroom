# frozen_string_literal: true
class GroupsController < ApplicationController
  include OrganizationAuthorization

  before_action :ensure_team_management_flipper_is_enabled
  before_action :set_group
  before_action :set_grouping
  before_action :set_member, only: [:remove_membership]

  def show
  end

  def remove_membership
    repo_access = RepoAccess.find_by(user: @user, organization: @organization)

    if repo_access.present?
      @group.repo_accesses.delete(repo_access)
      flash[:success] = "\@#{@user.github_user.login} has been removed from group \"#{@group.title}\"!"
    else
      flash[:error] = 'Student is not a member of this classroom'
    end
    redirect_to organization_grouping_group_path(@organization, @grouping, @group)
  end

  private

  def set_grouping
    @grouping = Grouping.find_by!(slug: params[:grouping_id])
  end

  def set_group
    @group = Group.includes(:repo_accesses).find_by!(slug: params[:id])
  end

  def set_member
    @user = User.find_by!(id: params[:user_id])
  end
end
