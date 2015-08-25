class GroupAssignmentInvitationsController < InvitationsController
  skip_before_action :set_organization, :authorize_organization_access

  def show
    @groups = @invitation.groups.map { |group| [group.title, group.id] }
  end

  def accept_invitation
    group       = Group.find_by(id: group_params[:id])
    group_title = group_params[:title]

    if (full_repo_name = @invitation.redeem_for(current_user, group, group_title))
      render partial: 'success',
             locals: { repo_url: "https://github.com/#{full_repo_name}" },
             layout: 'invitations'
    else
      flash[:error] = 'An error has occured, please refresh the page and try again.'
      redirect_to :show
    end
  end

  private

  def group_params
    params
      .require(:group)
      .permit(:id, :title)
  end

  def set_invitation
    @invitation = GroupAssignmentInvitation.find_by_key!(params[:id])
  end
end
