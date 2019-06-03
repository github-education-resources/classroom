# frozen_string_literal: true

module Stafftools
  class OrganizationsController < StafftoolsController
    before_action :set_organization_and_webhook

    def show; end

    def remove_user
      user = User.find(params[:user_id])

      if Assignment.find_by(creator: user).present?
        flash[:error] = "This user owns at least one assignment and cannot be deleted"
      else
        @organization.users.delete(user)
        flash[:success] = "The user has been removed from the classroom"
      end

      redirect_to stafftools_organization_path(@organization.id)
    end

    def ensure_webhook_is_active
      if @organization_webhook.ensure_webhook_is_active!
        flash[:success] = "The organization webhook active."
      else
        flash[:error] = "The organization webhook could not be activated. " \
        "This is probabily because there isn't a user in this classroom with the `admin:org_hook` scope."
      end
      redirect_to stafftools_organization_path(@organization.id)
    end

    private

    def set_organization_and_webhook
      @organization = Organization.includes(:users).find_by!(id: params[:id])
      @organization_webhook = @organization.organization_webhook
    end
  end
end
