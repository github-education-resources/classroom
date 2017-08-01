# frozen_string_literal: true

module GitHubClassroom
  class NullStatsD
    def increment(stat, opts = {}); end

    def timing(stat, ms, opts = {}); end
  end
end
