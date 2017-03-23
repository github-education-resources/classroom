module GitHubClassroom
  def self.github_client(options = {})
    client_options = {
      client_id:     Rails.application.secrets.github_client_id,
      client_secret: Rails.application.secrets.github_client_secret
    }.merge!(options)

    if client_options.has_key?(:access_token)
      client_options.delete(:client_id)
      client_options.delete(:client_secret)
    end

    if is_ghe
      client_options.merge!({
        api_endpoint: "https://%{hostname}/api/v3/" % [hostname: Rails.application.secrets.github_enterprise_hostname]
      })
    end

    Octokit::Client.new(client_options)
  end

  def self.is_ghe()
    !!(Rails.application.secrets.github_enterprise_enabled == true)
  end
end
