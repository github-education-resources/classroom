# frozen_string_literal: true

module Stafftools
  class GroupAssignmentInvitationsController < StafftoolsController
    before_action :set_group_assignment_invitation

    def show; end

    private

    def set_group_assignment_invitation
      @group_assignment_invitation = GroupAssignmentInvitation.find_by!(id: params[:id])
    end
  end
end
