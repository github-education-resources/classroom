class OrganizationsController < ApplicationController
  before_action :redirect_to_root, unless: :logged_in?

  before_action :verify_organization_ownership, except: [:new, :create]
  before_action :set_organization,              except: [:new, :create]

  def new
    @organization               = Organization.new
    @users_github_organizations = current_user.github_client.users_organizations.
                                  collect { |org| [org.login, org.id] }
  end

  def create
    github_id = new_organization_params["github_id"].to_i

    if Organization.where(github_id: github_id).present?
      redirect_to new_organization_path, alert: 'Organization has already been added'
    else
      if current_user.github_client.is_organization_admin?(github_id)
        organization = Organization.new(new_organization_params)
        organization.users << current_user

        if organization.save
          flash[:success] = 'Organization was successfully added'
          redirect_to dashboard_path
        else
          redirect_to :back, error: 'Could not add your organization'
        end
      else
        redirect_to new_organization_path, alert: 'You are not an administrator of this organization'
      end
    end
  end

  def show
  end

  def edit
  end

  def update
    if @organization.update!(update_organization_params)
      flash[:success] = 'Organization updated'
      redirect_to @organization
    else
      redirect_to edit
    end
  end

  def destroy
    if @organization.destroy
      flash[:success] = 'Organization was successfully removed'
      redirect_to dashboard_path
    else
      redirect_to back, error: 'Could not remove the organization'
    end
  end

  private

  def new_organization_params
    params.require(:organization).permit(:title, :github_id)
  end

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def update_organization_params
    params.require(:organization).permit(:title)
  end

  def verify_organization_ownership
    unless current_user.organization_ids.include?(params[:id].to_i)
      redirect_to back, status: 401, error: 'Not authorized'
    end
  end
end
