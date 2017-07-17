# frozen_string_literal: true

class PagesController < ApplicationController
  layout "layouts/pages"

  skip_before_action :authenticate_user!

  def home
    redirect_to organizations_path if logged_in?
  end
end
