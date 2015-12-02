module Stafftools
  class OrganizationsController < StafftoolsController
    before_action :set_organization

    def show
    end

    private

    def set_organization
      @organization = Organization.find_by(id: params[:id])
    end
  end
end
