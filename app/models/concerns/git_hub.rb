module GitHub
  class Error < StandardError; end
  class Forbidden < StandardError; end
  class NotFound < StandardError; end

  # Public: Handle errors coming from Octokit
  #
  # Example
  #
  #   with_error_handling { @client.organization('github') }
  #
  # If an Octokit error has not occured the method continues as expected
  def with_error_handling
    yield
  rescue Octokit::Error => err
    case err
    when Octokit::Forbidden           then raise_github_forbidden_error
    when Octokit::NotFound            then raise_github_not_found_error
    when Octokit::ServerError         then raise_github_server_error
    when Octokit::UnprocessableEntity then raise_github_error(err)
    end
  end

  protected

  # Internal: header to bypass caching
  #
  # Example
  #   @client.organization(1, headers: no_cache_headers)
  #
  def no_cache_headers
    { 'Cache-Control' => 'no-cache, no-store' }
  end

  # Internal: Raise a GitHub::Forbidden error
  def raise_github_forbidden_error
    fail GitHub::Forbidden, 'You are forbidden from performing this action on github.com'
  end

  # Internal: Raise a GitHub::Error error
  def raise_github_server_error
    fail GitHub::Error, 'There seems to be a problem on github.com, please try again.'
  end

  # Internal: Raise a GitHub::Error error with a custom message from the
  # GitHub API
  def raise_github_error(err)
    fail GitHub::Error, build_error_message(err.errors.first)
  end

  # Internal: Raise a GitHub::NotFound error
  def raise_github_not_found_error
    fail GitHub::NotFound, 'Resource could not be found on github.com'
  end

  private

  # Internal: Build the error message from the GitHub API
  #
  # error - The Hash containing the various parts of the error message
  #
  # Returns the error message as a String
  # rubocop:disable AbcSize
  def build_error_message(error)
    return 'An error has occured' unless error.present?

    error_message = []

    error_message << error[:resource]
    error_message << error[:code].tr('_', ' ') if error[:message].nil?
    error_message << error[:field] if error[:message].nil?
    error_message << error[:message] unless error[:message].nil?

    error_message.map(&:to_s).join(' ')
  end
  # rubocop:enable AbcSize
end
