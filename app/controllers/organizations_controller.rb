class OrganizationsController < ApplicationController
  include OrganizationAuthorization

  before_action :authorize_organization_addition,     only: [:create]
  before_action :set_users_github_organizations,      only: [:new, :create]
  before_action :paginate_users_github_organizations, only: [:new, :create]

  skip_before_action :set_organization, :authorize_organization_access, only: [:index, :new, :create]

  decorates_assigned :organization

  def index
    @organizations = current_user.organizations.page(params[:page])
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(new_organization_params)

    if @organization.save
      redirect_to setup_organization_path(@organization)
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
    if @organization.update_attributes(deleted_at: Time.zone.now)
      DestroyResourceJob.perform_later(@organization)

      flash[:success] = "Your organization, @#{organization.login} is being reset"
      redirect_to organizations_path
    else
      render :edit
    end
  end

  def new_assignment
  end

  def invite
  end

  def setup
  end

  def setup_organization
    if @organization.update_attributes(update_organization_params)
      redirect_to invite_organization_path(@organization)
    else
      render :setup
    end
  end

  private

  def authorize_organization_access
    return if @organization.users.include?(current_user) || current_user.staff?

    begin
      github_organization.admin?(decorated_current_user.login) ? @organization.users << current_user : not_found
    rescue
      not_found
    end
  end

  def authorize_organization_addition
    new_github_organization = github_organization_from_params

    return if new_github_organization.admin?(decorated_current_user.login)
    fail NotAuthorized, 'You are not permitted to add this organization as a classroom'
  end

  def github_organization_from_params
    @github_organization_from_params ||= GitHubOrganization.new(current_user.github_client,
                                                                params[:organization][:github_id].to_i)
  end

  def new_organization_params
    github_org = github_organization_from_params.organization
    title      = github_org.name.present? ? github_org.name : github_org.login

    params
      .require(:organization)
      .permit(:github_id)
      .merge(users: [current_user])
      .merge(title: title)
  end

  def set_organization
    @organization = Organization.find_by!(slug: params[:id])
  end

  def set_users_github_organizations
    github_user = GitHubUser.new(current_user.github_client, current_user.uid)

    @users_github_organizations = github_user.organization_memberships.map do |membership|
      {
        classroom: Organization.unscoped.find_by(github_id: membership.organization.id),
        github_id: membership.organization.id,
        login:     membership.organization.login,
        role:      membership.role
      }
    end
  end

  def paginate_users_github_organizations
    @users_github_organizations = Kaminari.paginate_array(@users_github_organizations).page(params[:page]).per(24)
  end

  def update_organization_params
    params
      .require(:organization)
      .permit(:title)
  end
end
