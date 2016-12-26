# frozen_string_literal: true
module Stafftools
  class OrganizationsController < StafftoolsController
    before_action :set_organization

    def show; end

    def remove_user
      not_found unless true_user.try(:staff?)

      user = User.find(params[:user_id])

      if remove_user_from_github(user)
        @organization.users.delete(user)
      else
        flash[:error] = 'Could not remove the owner'
      end

      redirect_to stafftools_organization_path(@organization.id)
    end

    private

    def set_organization
      @organization = Organization.includes(:users).find_by!(id: params[:id])
    end

    def remove_user_from_github(user)
      github_organization = GitHubOrganization.new(@organization.github_client, @organization.github_id)
      github_organization.remove_organization_member(user.uid, remove_admin: true)
    end
  end
end
