# frozen_string_literal: true

module Organizations
  class Controller < ApplicationController
    before_action :ensure_this_organization
    before_action :ensure_this_organization_visible_to_current_user

    protected

    def add_user_to_organization_or_404
      github_organization = GitHubOrganization.new(current_user.github_client, this_organization.github_id)
      github_organization.admin?(current_user.github_user.login) ? this_organization.users << current_user : not_found
    end

    def ensure_this_organization
      not_found if this_organization.nil?
    end

    def ensure_this_organization_visible_to_current_user
      return true if this_organization.users.pluck(:id).include?(current_user.id)
      add_user_to_organization_or_404
    end

    def this_organization
      return @this_organization if defined?(@this_organization)
      organization_id = params[:organization_id] || params[:id]
      @this_organization = Organization.find_by!(slug: organization_id)
    end
    helper_method :this_organization
  end
end
