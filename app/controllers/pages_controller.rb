class PagesController < ApplicationController
  skip_before_action :ensure_logged_in

  def home
    redirect_to dashboard_path if logged_in?
  end
end
