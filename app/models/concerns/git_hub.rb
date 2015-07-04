module GitHub
  class Error < StandardError; end
  class Forbidden < StandardError; end
  class NotFound < StandardError; end

  # Public
  #
  def with_error_handling
    yield
  rescue Octokit::Error => err
    case err
    when Octokit::Forbidden then raise GitHub::Forbidden
    when Octokit::NotFound  then raise GitHub::NotFound

    when Octokit::ServerError
      raise GitHub::Error, 'There seems to be a problem on GitHub.com, please try again.'

    when Octokit::UnprocessableEntity
      raise GitHub::Error, build_error_message(err.errors.first)
    end
  end

  # Internal
  #
  def build_error_message(error)
    error_message = []

    if error.present?
      error_message << error[:resource]
      error_message << error[:code].gsub('_', ' ') if error[:message].nil?
      error_message << error[:field] if error[:message].nil?
      error_message << error[:message] unless error[:message].nil?
    else
      error_message << 'An error has occurred'
    end

    error_message.map(&:to_s).join(' ')
  end
end
