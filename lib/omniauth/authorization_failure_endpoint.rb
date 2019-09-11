# frozen_string_literal: true

module OmniAuth
  # rubocop:disable AbcSize
  class AuthorizationFailureEndpoint < OmniAuth::FailureEndpoint
    def redirect_to_failure
      base_url = "#{env['SCRIPT_NAME']}#{OmniAuth.config.path_prefix}/failure"
      launch_params = env["lti.launch_params"] ? env["lti.launch_params"].to_query : ""
      omniauth_params = {
        message:  env["omniauth.error.type"],
        strategy: env["omniauth.error.strategy"].name,
        origin: Rack::Utils.escape(env["omniauth.origin"])
      }.to_query

      redirect_url = "#{base_url}?#{omniauth_params}&#{launch_params}"
      Rack::Response.new(["302 Moved"], 302, "Location" => redirect_url).finish
    end
  end
  # rubocop:enable AbcSize
end
