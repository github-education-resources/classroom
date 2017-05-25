# frozen_string_literal: true

module Mobile
  module ApplicationHelper
    # Public: Is the request coming from a mobile device?
    #
    # Returns a boolean.
    def mobile?
      GitHubClassroom::Mobile.mobile_user_agent?(request.user_agent.to_s)
    end
  end
end
