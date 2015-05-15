class OrganizationsController < ApplicationController
  before_action :ensure_logged_in
  before_action :authorize_user!,  except: [:new, :create]
  before_action :set_organization, except: [:new, :create]

  def new
    @organization               = Organization.new
    @users_github_organizations = current_user.github_client.users_organizations.
                                  collect { |org| [org.login, [org.login, org.id]] }
  end

  def create
    org               = JSON.parse(params[:org])
    login, github_id  = org.first, org.last

    if Organization.where(github_id: github_id).present?
      redirect_to new_organization_path, alert: 'Classroom has already been added'
    else
      if current_user.github_client.is_organization_admin?(login)
        organization  = Organization.new(login: login, github_id: github_id)
        organization.users << current_user

        if organization.save
          flash[:success] = "Classroom was successfully added"
          redirect_to dashboard_path
        else
          redirect_to :back, error: "Could not create classroom"
        end
      else
        redirect_to new_organization_path, alert: 'You are not an administrator of this classroom'
      end
    end
  end

  def show
  end

  def destroy
    if @organization.destroy
      flash[:success] = 'Classroom was successfully deleted'
      redirect_to dashboard_path
    else
      redirect_to back, error: 'Could not delete classroom'
    end
  end

  private

  def authorize_user!
    begin
      has_user_id = Organization.find(params[:id]).user_ids.
                                 include?(current_user.id)
    rescue ActiveRecord::RecordNotFound
      has_user_id = false
    end

    unless has_user_id
      redirect_to '/404.html'
    end
  end

  def set_organization
    @organization = Organization.find(params[:id])
  end
end
