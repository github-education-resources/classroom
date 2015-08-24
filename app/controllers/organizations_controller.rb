class OrganizationsController < ApplicationController
  before_action :authorize_organization_addition, only:   [:create]
  before_action :set_organization,                except: [:new, :create]
  before_action :set_users_github_organizations,  only:   [:new, :create]

  decorates_assigned :organization

  rescue_from GitHub::Error,     with: :error
  rescue_from GitHub::Forbidden, with: :deny_access
  rescue_from GitHub::NotFound,  with: :deny_access

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(new_organization_params)

    if @organization.save
      redirect_to invite_organization_path(@organization)
    else
      render :new
    end
  end

  def show
    @assignments = Kaminari.paginate_array(@organization.all_assignments.sort_by(&:updated_at)).page(params[:page])
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
      InviteUserToClassroomJob.perform_later(id, email, current_user, @organization)
    end

    respond_to do |format|
      format.html { redirect_to @organization }
    end
  end

  private

  def authorize_organization_addition
    github_organization = GitHubOrganization.new(current_user.github_client, new_organization_params[:github_id].to_i)
    github_user         = GitHubUser.new(current_user.github_client)

    deny_access unless github_organization.admin?(github_user.login)
  end

  def deny_access
    flash[:error] = 'You are not authorized to perform this action'
    redirect_to :back
  end

  def error(exception)
    flash[:error] = exception.message
  end

  def new_organization_params
    params
      .require(:organization)
      .permit(:title, :github_id)
      .merge(users: [current_user])
  end

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def set_github_organization_owners
    organization_users_uids = @organization.users.pluck(:uid)
    github_organization     = GitHubOrganization.new(current_user.github_client, @organization.github_id)

    github_organization.organization_members(role: 'admin').delete_if do |member|
      organization_users_uids.include?(member.id)
    end
  end

  def set_users_github_organizations
    github_user = GitHubUser.new(current_user.github_client)

    @users_github_organizations = github_user.admin_organization_memberships.map do |membership|
      unless Organization.find_by(github_id: membership.organization.id)
        [membership.organization.login, membership.organization.id]
      end
    end.compact
  end

  def update_organization_params
    params
      .require(:organization)
      .permit(:title)
  end
end
