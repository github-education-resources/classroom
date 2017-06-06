# frozen_string_literal: true

module GitHub
  class Error < StandardError; end
  class Forbidden < Error; end
  class NotFound < Error; end
end
