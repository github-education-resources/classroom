module GitHub
  class Error < StandardError; end
  class Forbidden < Error; end
  class NotFound < Error; end

  autoload :APIHeaders, 'github/api_headers'
  autoload :Errors,     'github/errors'
end
