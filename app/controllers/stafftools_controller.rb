class StafftoolsController < ApplicationController
  layout 'staff'

  before_action :authorize_access
  before_action :set_resources

  def resources
  end

  def search
    respond_to do |format|
      format.html { render partial: 'stafftools/search_results', locals: { resources: @resources } }
    end
  end

  private

  def authorize_access
    not_found unless current_user.try(:staff?)
  end

  def set_resources
    resource_query = params[:query].present? ? match_phrase_prefix(params[:query]) : {}
    @resources     = StafftoolsIndex::User.query(resource_query).page(params[:page]).per(20)
  end

  def match_phrase_prefix(query)
    { bool: { should: %w(id uid name login).map { |field| { 'match_phrase_prefix' => { field => query } } } } }
  end
end
