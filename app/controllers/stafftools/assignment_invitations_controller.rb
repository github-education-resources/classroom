module Stafftools
  class AssignmentInvitationsController < StafftoolsController
    before_action :set_assignment_invitation

    def show
    end

    def edit
    end

    def update
    end

    def destroy
    end

    private

    def set_assignment_invitation
      @assignment_invitation = AssignmentInvitation.find_by(id: params[:id])
    end
  end
end
