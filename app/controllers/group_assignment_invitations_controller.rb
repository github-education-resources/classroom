class GroupAssignmentInvitationsController < ApplicationController
  before_action :authenticate_with_pre_login_destination, only: [:show]
  before_action :set_invitation

  layout 'layouts/invitations'

  def show
    @grouping = @invitation.grouping
    @groups   = @grouping.groups.map { |group| [group.title, group.id] }
  end

  def accept_invitation
    if @invitation.redeemed?(current_user, group_params)
      render :success, status: 201
    else
      render :error, status: 503
    end
  end

  private

  def authenticate_with_pre_login_destination
    return if logged_in?
    session[:pre_login_destination] = "#{request.base_url}#{request.path}"
    redirect_to login_path
  end

  def group_params
    params
      .require(:group)
      .permit(:id, :title)
  end

  def set_invitation
    @invitation = GroupAssignmentInvitation.find_by_key!(params[:id])
  end
end
