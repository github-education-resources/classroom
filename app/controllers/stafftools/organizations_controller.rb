# frozen_string_literal: true
module Stafftools
  class OrganizationsController < StafftoolsController
    before_action :set_organization

    def show; end

    def remove_user
      not_found unless true_user.try(:staff?)

      user = User.find(params[:user_id])
      @organization.users.delete(user)

      redirect_to stafftools_organization_path(@organization.id)
    end

    private

    def set_organization
      @organization = Organization.includes(:users).find_by!(id: params[:id])
    end
  end
end
