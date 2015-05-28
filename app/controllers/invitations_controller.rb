class InvitationsController < ApplicationController
  before_action :authenticate_with_pre_login_destination, only: [:show]
  before_action :set_organization,                        only: [:create]

  def create
    @team = current_user.github_client.team(invitation_params[:team_id]) ||
      current_user.github_client.create_team(@organization.github_id,
                                             {name: invitation_params[:title], permission: 'push'})

    @invitation = Invitation.new(title:           @team.name,
                                 team_id:         @team.id,
                                 organization_id: @organization.id,
                                 user_id:         current_user.id)

    if @invitation.save && @organization.update_attributes(students_team_id: @invitation.team_id)
      UpdateGithubTeamJob.perform_later(current_user, @team.id, {description: 'Managed by Classroom'})

      flash[:success] = "Your team \"#{@team.name}\" and its invitation are ready to go!"
      redirect_to @organization
    else
      render 'organizations/invite'
    end
  end

  def show
    @invitation   = Invitation.find_by_key!(params[:id])
    @organization = Organization.find(@invitation.organization_id)

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
