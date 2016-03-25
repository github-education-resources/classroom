module GitHub
  module Errors
    class << self
      def with_error_handling
        yield
      rescue Octokit::Error => err
        case err
        when Octokit::Forbidden           then raise_github_forbidden_error
        when Octokit::NotFound            then raise_github_not_found_error
        when Octokit::ServerError         then raise_github_server_error
        when Octokit::Unauthorized        then raise_github_forbidden_error
        else
          raise_github_error(err)
        end
      end

      protected

      def raise_github_forbidden_error
        raise GitHub::Forbidden, 'You are forbidden from performing this action on github.com'
      end

      def raise_github_server_error
        raise GitHub::Error, 'There seems to be a problem on github.com, please try again.'
      end

      def raise_github_error(err)
        raise GitHub::Error, build_error_message(err.errors.first)
      end

      def raise_github_not_found_error
        raise GitHub::NotFound, 'Resource could not be found on github.com'
      end

      private

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
  end
end
