# frozen_string_literal: true

module GitHubClassroom
  def self.github_client(options = {})
    client_options = {
      client_id:     Rails.application.secrets.github_client_id,
      client_secret: Rails.application.secrets.github_client_secret,
      auto_paginate: true
    }.merge!(options)

    Octokit::Client.new(client_options)
  end
end
