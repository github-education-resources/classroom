class InvitationsController < ApplicationController
  before_action :authenticate_with_pre_login_destination, only: [:show]
  before_action :set_organization,                        only: [:create]

  def create
    inviter = Inviter.new(current_user, @organization, invitation_params[:team_id], invitation_params[:title])
    @invitation = inviter.create_invitation

    if @invitation.save
      flash[:success] = "Your team \"#{@team.name}\" and its invitation are ready to go!"
      redirect_to @organization
    else
      flash[:error] = "Invitation failed because team already exists"
      redirect_to invite_organization_path(params[:organization_id])
    end
  end

  def show
    @invitation = Invitation.find_by_key!(params[:id])

    if @invitation.redeem(current_user.github_client.user)
      render text: 'Success!', status: 200
    else
      render text: 'Failed :-(', status: 503
    end
  end

  private

  def authenticate_with_pre_login_destination
    unless logged_in?
      session[:pre_login_destination] = "#{request.base_url}#{request.path}"
      redirect_to login_path
    end
  end

  def invitation_params
    params.require(:invitation).permit(:title, :team_id)
  end

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end
end
