class PagesController < ApplicationController
  layout 'layouts/pages'

  skip_before_action :authenticate_user!, :set_organization, :authorize_organization_access

  def home
    redirect_to organizations_path if logged_in?
  end
end
