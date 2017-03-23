options = {
  scope: 'user:email,repo,delete_repo,admin:org,admin:org_hook'
}

if GitHubClassroom.is_ghe
  hostname = Rails.application.secrets.github_enterprise_hostname

  options.merge!({
    site: 'https://%s/api/v3' % [hostname],
    authorize_url: 'https://%s/login/oauth/authorize' % [hostname],
    token_url: 'https://%s/login/oauth/access_token' % [hostname]
  })
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, Rails.application.secrets.github_client_id,
           Rails.application.secrets.github_client_secret,
           {
               :client_options => options
           }
end