class OrganizationsController < ApplicationController
  before_action :redirect_to_root,               unless: :logged_in?
  before_action :set_organization,               except: [:new, :create]
  before_action :set_users_github_organizations, only:   [:new, :create]

  rescue_from GitHub::Error,     with: :error
  rescue_from GitHub::Forbidden, with: :deny_access

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(new_organization_params)
    @organization.users << current_user

    if @organization.save
      redirect_to invite_organization_path(@organization)
    else
      render :new
    end
  end

  def show
    @assignments = @organization.all_assignments.sort_by(&:created_at)
  end

  def edit
  end

  def update
    if @organization.update_attributes(update_organization_params)
      flash[:success] = "Organization \"#{@organization.title}\" updated"
      redirect_to @organization
    else
      render :edit
    end
  end

  def destroy
    flash_message = "Organization \"#{@organization.title}\" was removed"
    @organization.destroy

    flash[:success] = flash_message
    redirect_to dashboard_path
  end

  def new_assignment
  end

  def invite
    @organization_owners = set_github_organization_owners
  end

  def invite_users
    params[:github_owners].each do |login, id|
      email = params[:github_owner_emails][login]
      InviteUserToClassroomJob.perform_later(id, login, email, current_user, @organization)
    end

    respond_to do |format|
      format.html { redirect_to @organization }
    end
  end

  private

  def deny_access
    flash[:error] = 'You are not authorized to perform this action'
    redirect_to_root
  end

  def error(exception)
    flash[:error] = exception.message
  end

  def set_github_organization_owners
    organization_users_uids = @organization.users.pluck(:uid).map(&:to_i)
    github_organization     = GitHubOrganization.new(current_user.github_client, @organization.github_id)

    github_organization.organization_members(role: 'admin').delete_if do |member|
      organization_users_uids.include?(member.id)
    end
  end

  def new_organization_params
    params
      .require(:organization)
      .permit(:title, :github_id)
  end

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def set_users_github_organizations
    github_organization = GitHubOrganization.new(current_user.github_client, nil)
    @users_github_organizations = github_organization.organization_memberships(state: 'active').collect do |org|
      [org.organization.login, org.organization.id] if org.role == 'admin'
    end.compact
  end

  def update_organization_params
    params
      .require(:organization)
      .permit(:title)
  end
end
