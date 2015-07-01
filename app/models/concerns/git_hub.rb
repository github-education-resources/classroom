module GitHub
  class Error < StandardError; end
  class Forbidden < StandardError; end
  class NotFound < StandardError; end

  # Internal
  #
  def build_error_message(errors)
    code     = errors[:code].gsub('_', ' ')
    resource = errors[:resource]
    field    = errors[:field]

    "#{resource} #{field} #{code}"
  end

  # Internal
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
end
