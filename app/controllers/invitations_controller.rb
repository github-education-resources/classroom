class InvitationsController < ApplicationController
  before_action :authenticate_with_pre_login_destination, only: [:show]

  before_action :set_invitation,         except: [:index, :new, :create]
  before_action :set_organization,       only:   [:index, :new, :create]
  before_action :set_organization_teams, only:   [:new, :create]

  def show
    @organization = Organization.find(@invitation.organizations_id)

    if @organization.user_ids.include?(current_user.id)
      flash[:notice] = 'You are an admin of this organization'
      redirect_to organization_invitations_path(@organization)
    else
      # TODO: should look into putting a background job in here
      # to remove users that aren't admins anymore
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

  def index
    @invitations = Invitation.where(organizations_id: @organization.id)
  end

  def new
    @invitation = Invitation.new
  end

  def create
    @invitation = Invitation.new(invitation_params)
    @invitation.organizations_id = @organization.id

    if @invitation.save
      flash[:success] = 'Invitation Created!'
      redirect_to organization_invitations_path(@organization)
    else
      render :new
    end
  end

  def destroy
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

  def set_invitation
    @invitation = Invitation.find_by_key!(params[:id])
  end

  def set_organization
    @organization = Organization.find_by(id: params[:organization_id])
  end

  def set_organization_teams
    @organizations_teams = current_user.github_client.organization_teams(@organization.github_id).
      collect { |team| [team.slug, team.id] }
  end
end
