class ErrorsController < ApplicationController
  def not_found
    render template: "errors/not_found.html.erb", status: :not_found
  end
end
