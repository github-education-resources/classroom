# frozen_string_literal: true

module GitHub
  class Error < StandardError; end
  class Forbidden < Error; end
  class NotFound < Error; end

  REPOSITORY_REGEX = /[a-zA-Z0-9\._-]+/
  USERNAME_REGEX = /[a-zA-Z0-9_-]+/
end
