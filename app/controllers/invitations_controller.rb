class InvitationsController < ApplicationController
  before_action :authenticate_with_pre_login_destination, only: [:show]

  def create
    @invitation   = Invitation.new(invitation_params)
    @organization = Organization.find_by(id: params[:organization_id])

    @invitation.organization = @organization

    if @invitation.save
      flash[:success] = 'Invitation Created!'
      redirect_to organization_invitations_path(@organization)
    else
      render :new
    end
  end

  def show
    begin
      @invitation = Invitation.find_by_key!(params[:id])
    rescue ActiveRecord::RecordNotFound
      render text: 'Invitation does not exist :-(', status: 503
    end

    @organization = Organization.find(@invitation.organizations_id)

    if @organization.user_ids.include?(current_user.id)
      flash[:notice] = 'You are an admin of this organization'
      redirect_to organization_invitations_path(@organization)
    else
      @organization_admin = @organization.users.to_a.keep_if do |user|
        user.github_client.organization_admin?(@organization.github_id)
      end.first

      if @organization_admin.present?
        new_member_login = current_user.github_client.user.login
        if @organization_admin.github_client.add_team_membership(@invitation.team_id, new_member_login)
          render text: 'Success!', status: 200
        else
          render text: 'Failed :-(', status: 503
        end
      else
        render text: 'Failed :-(', status: 503
      end
    end
  end

  def destroy
    @invitation = Invitation.find_by_key(params[:id])

    organizations_id = @invitation.organizations_id
    @invitation.destroy

    flash[:success] = 'Invitation was deleted'
    redirect_to dashboard_path
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
end
