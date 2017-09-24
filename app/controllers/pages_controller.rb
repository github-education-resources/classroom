# frozen_string_literal: true

class PagesController < ApplicationController
  layout "layouts/pages"

  skip_before_action :authenticate_user!

  def home
    if logged_in?
      redirect_to organizations_path
    else
      use_content_security_policy_named_append(:unauthed_video)
    end
  end
end
