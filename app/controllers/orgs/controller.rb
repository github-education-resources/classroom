# frozen_string_literal: true

module Orgs
  class Controller < ApplicationController
    before_action :ensure_current_organization
    before_action :ensure_current_organization_visible_to_current_user

    protected

    def add_current_user_to_current_organization_or_404
      github_organization = GitHubOrganization.new(current_user.github_client, current_organization.github_id)
      return not_found unless github_organization.admin?(current_user.github_user.login)
      current_organization.users << current_user
      true
    end

    def ensure_current_organization
      not_found if current_organization.nil?
    end

    def ensure_current_organization_visible_to_current_user
      return true if current_organization.users.pluck(:id).include?(current_user.id)
      add_current_user_to_current_organization_or_404
    end

    def current_organization
      return @current_organization if defined?(@current_organization)
      organization_id = params[:organization_id] || params[:id]
      @current_organization = Organization.find_by!(slug: organization_id)
    end
    helper_method :current_organization

    def failbot_context
      super unless current_organization.nil?
      super.merge(organization: current_organization.id)
    end
  end
end
