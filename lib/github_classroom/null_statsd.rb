# frozen_string_literal: true

module GitHubClassroom
  class NullStatsD
    def increment(stat, opts = {}); end

    def time(stat, opts = {}); end
  end
end
