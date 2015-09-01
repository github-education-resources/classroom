class PagesController < ApplicationController
  skip_before_action :ensure_logged_in, :set_organization, :authorize_organization_access

  def home
    redirect_to organizations_path if logged_in?
  end
end
