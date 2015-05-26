class OrganizationsController < ApplicationController
  before_action :redirect_to_root,          unless: :logged_in?
  before_action :ensure_organization_admin, except: [:new, :create]

  before_action :set_organization,               except: [:new, :create]
  before_action :set_users_github_organizations, only:   [:new, :create]

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(new_organization_params)

    if current_user.github_client.organization_admin?(new_organization_params["github_id"])
      @organization.users << current_user

      if @organization.save
        flash[:success] = "Organization \"#{@organization.title}\" was successfully added"
        redirect_to @organization
      else
        render :new
      end
    else
      redirect_to new_organization_path, alert: 'You are not an administrator of this organization'
    end
  end

  def show
    @invitation = @organization.invitation
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
    title = @organization.title
    @organization.destroy

    flash[:success] = "Organization \"#{title}\" was removed"
    redirect_to dashboard_path
  end

  private

  def ensure_organization_admin
    github_id = Organization.find(params[:id]).github_id
    unless current_user.github_client.organization_admin?(github_id)
      render text: 'Unauthorized', status: 401
    end
  end

  def new_organization_params
    params.require(:organization).permit(:title, :github_id)
  end

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def set_users_github_organizations
    @users_github_organizations = current_user.github_client.users_organizations.
                                  collect { |org| [org.login, org.id] }
  end

  def update_organization_params
    params.require(:organization).permit(:title)
  end
end
