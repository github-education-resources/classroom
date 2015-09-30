class StafftoolsController < ApplicationController
  layout 'staff'

  before_action :authorize_access
  before_action :set_users, only: [:impersonate, :users]

  def impersonate
  end

  def users
    respond_to do |format|
      format.html { render partial: 'stafftools/impersonate/user_results', locals: { users: @users } }
    end
  end

  private

  def authorize_access
    not_found unless current_user.try(:staff?)
  end

  def set_users
    match_phrase_prefix = { match_phrase_prefix: { login: params[:query] } }
    wildcard            = { wildcard:            { login: '*' }            }

    user_query = params[:query].present? ? match_phrase_prefix : wildcard
    @users = UsersIndex::User.query(user_query).page(params[:page]).per(10)
  end
end
