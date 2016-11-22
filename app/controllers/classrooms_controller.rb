# frozen_string_literal: true
class ClassroomsController < ApplicationController
  include OrganizationAuthorization

  before_action :ensure_team_management_flipper_is_enabled, only: [:show_groupings]

  before_action :authorize_organization_addition,     only: [:create]
  before_action :set_users_github_organizations,      only: [:index, :new, :create]
  before_action :add_current_user_to_organizations,   only: [:index]
  before_action :paginate_users_github_organizations, only: [:new, :create]

  skip_before_action :set_organization, :authorize_organization_access, only: [:index, :new, :create]

  def index
    @classrooms = current_user.classrooms.includes(:users).page(params[:page])
  end

  def new
    @classroom = Classroom.new
  end

  def create
    @classroom = Classroom.new(new_classroom_params)

    if @classroom.save
      redirect_to setup_classroom_path(@classroom)
    else
      render :new
    end
  end

  def show
    @assignments = Kaminari
                   .paginate_array(@classroom.all_assignments(with_invitations: true)
                   .sort_by(&:updated_at))
                   .page(params[:page])
  end

  def edit
  end

  def invitation
  end

  def show_groupings
    @groupings = @classroom.groupings
  end

  def update
    if @classroom.update_attributes(update_classroom_params)
      flash[:success] = "Classroom \"#{@classroom.title}\" updated"
      redirect_to @classroom
    else
      render :edit
    end
  end

  def destroy
    if @classroom.update_attributes(deleted_at: Time.zone.now)
      DestroyResourceJob.perform_later(@classroom)

      flash[:success] = "Your classroom, #{@classroom.title} is being reset"
      redirect_to classrooms_path
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

  def setup_classroom
    if @classroom.update_attributes(update_classroom_params)
      redirect_to invite_classroom_path(@classroom)
    else
      render :setup
    end
  end

  private

  def authorize_organization_addition
    new_github_organization = github_organization_from_params

    return if new_github_organization.admin?(current_user.github_user.login)
    raise NotAuthorized, 'You are not permitted to add this organization as a classroom'
  end

  def github_organization_from_params
    @github_organization_from_params ||= GitHubOrganization.new(current_user.github_client,
                                                                params[:organization][:github_id].to_i)
  end

  def new_organization_params
    github_org = github_organization_from_params
    title      = github_org.name.present? ? github_org.name : github_org.login

    params
      .require(:organization)
      .permit(:github_id)
      .merge(users: [current_user])
      .merge(title: title)
  end

  def set_classroom
    @classroom = Classroom.find_by!(slug: params[:id])
  end

  def set_users_github_organizations
    @users_github_organizations = current_user.github_user.organization_memberships.map do |membership|
      {
        classroom: Classroom.unscoped.includes(:users).find_by(github_organization_id: membership.organization.id),
        github_id: membership.organization.id,
        login:     membership.organization.login,
        role:      membership.role
      }
    end
  end

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

  def create_user_organization_access(classroom)
    github_org = GitHubOrganization.new(current_user.github_client, classroom.github_organization_id)
    return unless github_org.admin?(current_user.github_user.login)
    organization.users << current_user
  end

  def paginate_users_github_organizations
    @users_github_organizations = Kaminari.paginate_array(@users_github_organizations).page(params[:page]).per(24)
  end

  def update_classroom_params
    params
      .require(:classroom)
      .permit(:title)
  end
end
