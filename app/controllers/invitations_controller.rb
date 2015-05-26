class InvitationsController < ApplicationController
  before_action :authenticate_with_pre_login_destination, only: [:show]

  def show
    begin
      @invitation = Invitation.find_by_key!(params[:id])
    rescue ActiveRecord::RecordNotFound
      render text: 'Invitation does not exist :-(', status: 503 and return
    end

    @organization = Organization.find(@invitation.organization_id)

    if @organization.user_ids.include?(current_user.id)
      flash[:notice] = 'You are an admin of this organization'
      redirect_to @organization
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

  private

  def authenticate_with_pre_login_destination
    unless logged_in?
      session[:pre_login_destination] = "#{request.base_url}#{request.path}"
      redirect_to login_path
    end
  end
end
