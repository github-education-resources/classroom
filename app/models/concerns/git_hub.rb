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
    when Octokit::Forbidden           then raise_github_forbidden_error
    when Octokit::NotFound            then raise_github_not_found_error
    when Octokit::ServerError         then raise_github_server_error
    when Octokit::UnprocessableEntity then raise_github_error(err)
    end
  end

  protected

  def raise_github_forbidden_error
    fail GitHub::Forbidden, 'You are forbidden from performing this action on github.com'
  end

  def raise_github_server_error
    fail GitHub::Error, 'There seems to be a problem on github.com, please try again.'
  end

  def raise_github_error(err)
    fail GitHub::Error, build_error_message(err.errors.first)
  end

  def raise_github_not_found_error
    fail GitHub::NotFound, 'Resource could not be found on github.com'
  end

  private

  # Internal
  #
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
