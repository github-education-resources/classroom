class OrganizationsController < ApplicationController
  before_action :redirect_to_root,               unless: :logged_in?
  before_action :ensure_organization_admin,      except: [:new, :create]
  before_action :set_organization,               except: [:new, :create]
  before_action :set_users_github_organizations, only:   [:new, :create]

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(new_organization_params)
    @organization.users << current_user

    if @organization.save
      redirect_to @organization
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

  private

  def ensure_organization_admin
    github_id = Organization.find(params[:id]).github_id

    return if current_user.github_client.organization_admin?(github_id)
    render text: 'Unauthorized', status: 401
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
    @users_github_organizations = current_user.github_client.organization_memberships.map do |org|
      [org.organization.login, org.organization.id] if org.role == 'admin'
    end.compact
  end

  def update_organization_params
    params
      .require(:organization)
      .permit(:title)
  end
end
