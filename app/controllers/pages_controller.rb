class PagesController < ApplicationController
  def home
    redirect_to dashboard_path if logged_in?
  end
end
