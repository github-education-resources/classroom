class OrganizationsController < ApplicationController
  include OrganizationAuthorization

  before_action :authorize_organization_addition, only: [:create]
  before_action :set_users_github_organizations,  only: [:new, :create]

  skip_before_action :set_organization, :authorize_organization_access, only: [:index, :new, :create]

  decorates_assigned :organization

  rescue_from ActiveRecord::RecordInvalid, with: :error
  rescue_from GitHub::Error,               with: :error
  rescue_from GitHub::Forbidden,           with: :deny_access
  rescue_from GitHub::NotFound,            with: :deny_access

  def index
    @organizations = current_user.organizations.page(params[:page])
  end

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
    if @organization.update_attributes(deleted_at: Time.zone.now)
      DestroyResourceJob.perform_later(@organization)

      flash[:success] = "Your organization, @#{organization.login} is being removed"
      redirect_to organizations_path
    else
      render :edit
    end
  end

  def new_assignment
  end

  def invite
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
    new_github_organization = GitHubOrganization.new(current_user.github_client,
                                                     new_organization_params[:github_id].to_i)

    deny_access unless new_github_organization.admin?(decorated_current_user.login)
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
    @organization = Organization.friendly.find(params[:id])
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
