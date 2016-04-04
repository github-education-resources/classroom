class API::SigninController < ApplicationController
  def index
    if logged_in?
      respond_to do |format|
        format.json { render 'file' => '/api/signin/loggedin.json.erb', 'content_type' => 'application/json' }
      end
    else
      redirect_to login_path
    end
  end
end
