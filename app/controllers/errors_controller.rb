class ErrorsController < ApplicationController
	def error404
		render template: "errors/simple_404.html.erb", status: :not_found
	end
end