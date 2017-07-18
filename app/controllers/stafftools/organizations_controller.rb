# frozen_string_literal: true

module Stafftools
  class OrganizationsController < StafftoolsController
    before_action :set_organization

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

    private

    def set_organization
      @organization = Organization.includes(:users).find_by!(id: params[:id])
    end
  end
end
