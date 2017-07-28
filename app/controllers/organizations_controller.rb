# frozen_string_literal: true

class OrganizationsController < ApplicationController
  include OrganizationAuthorization

  before_action :ensure_team_management_flipper_is_enabled, only: [:show_groupings]

  before_action :authorize_organization_addition,     only: [:create]
  before_action :set_users_github_organizations,      only: %i[index new create]
  before_action :add_current_user_to_organizations,   only: [:index]
  before_action :paginate_users_github_organizations, only: %i[new create]

  skip_before_action :set_organization, :authorize_organization_access, only: %i[index new create]

  def index
    @organizations = current_user.organizations.includes(:users).page(params[:page])
  end

  def new
    @organization = Organization.new
  end

  # rubocop:disable MethodLength
  def create
    result = Organization::Creator.perform(
      github_id: new_organization_params[:github_id],
      users: new_organization_params[:users]
    )

    if result.success?
      @organization = result.organization
      redirect_to setup_organization_path(@organization)
    else
      flash[:error] = result.error
      redirect_to new_organization_path
    end
  end
  # rubocop:enable MethodLength

  def show
    @assignments = Kaminari
                   .paginate_array(@organization.all_assignments(with_invitations: true)
                   .sort_by(&:updated_at))
                   .page(params[:page])
  end

  def edit; end

  def invitation; end

  def show_groupings
    @groupings = @organization.groupings
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

      flash[:success] = "Your organization, @#{@organization.github_organization.login} is being reset"
      redirect_to organizations_path
    else
      render :edit
    end
  end

  def new_assignment; end

  def invite; end

  def setup; end

  def setup_organization
    if @organization.update_attributes(update_organization_params)
      redirect_to invite_organization_path(@organization)
    else
      render :setup
    end
  end

  private

  def authorize_organization_addition
    new_github_organization = github_organization_from_params

    return if new_github_organization.admin?(current_user.github_user.login)
    raise NotAuthorized, "You are not permitted to add this organization as a classroom"
  end

  def github_organization_from_params
    @github_organization_from_params ||= GitHubOrganization.new(current_user.github_client,
                                                                params[:organization][:github_id].to_i)
  end

  def new_organization_params
    params.require(:organization).permit(:github_id).merge(users: [current_user])
  end

  def set_organization
    @organization = Organization.find_by!(slug: params[:id])
  end

  # rubocop:disable AbcSize
  def set_users_github_organizations
    @users_github_organizations = current_user.github_user.organization_memberships.map do |membership|
      {
        classroom:   Organization.unscoped.includes(:users).find_by(github_id: membership.organization.id),
        github_id:   membership.organization.id,
        login:       membership.organization.login,
        owner_login: membership.user.login,
        role:        membership.role
      }
    end
  end
  # rubocop:enable AbcSize

  # Check if the current user has any organizations with admin privilege,
  # if so add the user to the corresponding classroom automatically.
  def add_current_user_to_organizations
    @users_github_organizations.each do |organization|
      classroom = organization[:classroom]
      if classroom.present? && !classroom.users.include?(current_user)
        create_user_organization_access(classroom)
      end
    end
  end

  def create_user_organization_access(organization)
    github_org = GitHubOrganization.new(current_user.github_client, organization.github_id)
    return unless github_org.admin?(current_user.github_user.login)
    organization.users << current_user
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
