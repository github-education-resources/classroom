class OrganizationsController < ApplicationController
  before_action :ensure_logged_in
  before_action :authorize_user!,  only: :show
  before_action :set_organization, only: :show

  def new
    @organization = Organization.new
    @users_github_organizations = current_user.github_client
      .users_organizations.collect { |org| [org.login, org.id] }
  end

  def create
    github_organization_id = params[:org_id].to_i

    if Organization.where(github_id: github_organization_id).present?
      redirect_to new_organization_path, alert: 'Classroom has already been added'
    elsif !current_user.github_client.is_organization_owner?(github_organization_id)
      redirect_to new_organization_path, alert: 'You are not an owner of this classroom'
    else
      login = current_user.github_client.organization(github_organization_id).login

      @organization = Organization.new(login: login, github_id: github_organization_id)
      @organization.users << current_user

      if @organization.save
        redirect_to dashboard_path
      else
        redirect_to new_organization_path, error: "Could not create classroom"
      end
    end
  end

  def show
  end

  private

  def authorize_user!
    begin
      has_user_id = Organization.find(params[:id]).user_ids.include?(current_user.id)
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
