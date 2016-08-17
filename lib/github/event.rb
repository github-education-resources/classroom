# frozen_string_literal: true
module GitHub
  class Search
    attr_accessor :event_client

    def initialize(access_token, options = { auto_paginate: false })
      options[:access_token] = access_token

      @event_client = Octokit::Client.new(options)
    end

    def latest_push_event(repo_id, options = { per_page: 50, page: 1 })
      events = event_client.events(repo_id, options).filter { |e| e.type == 'PushEvent' }
      events.length.positive? ? events.first : nil
    end
  end
end
