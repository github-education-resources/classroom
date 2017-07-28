# frozen_string_literal: true

module GitHub
  module Errors
    class << self
      def with_error_handling
        yield
      rescue Octokit::Error => err
        process_octokit_error(err)
      end

      protected

      # rubocop:disable CyclomaticComplexity
      def process_octokit_error(error)
        case error
        when Octokit::Forbidden           then raise_github_forbidden_error
        when Octokit::NotFound            then raise_github_not_found_error
        when Octokit::ServerError         then raise_github_server_error
        when Octokit::TooManyRequests     then raise_github_too_many_requests
        when Octokit::Unauthorized        then raise_github_forbidden_error
        when Octokit::UnprocessableEntity then raise_github_unprocessable(error)
        else
          raise_github_error(error)
        end
      end
      # rubocop:enable CyclomaticComplexity

      private

      # rubocop:disable AbcSize
      def build_error_message(error)
        return "An error has occurred" if error.errors.blank?

        error.errors.map do |err|
          error_message = []

          error_message << "#{err[:resource]}:"
          error_message << err[:code].tr("_", " ") if err[:message].nil?
          error_message << err[:field] if err[:message].nil?
          error_message << err[:message] unless err[:message].nil?

          error_message.map(&:to_s).join(" ")
        end.join(" ")
      end
      # rubocop:enable AbcSize

      def raise_github_error(error)
        raise GitHub::Error, build_error_message(error)
      end

      def raise_github_forbidden_error
        raise GitHub::Forbidden, "You are forbidden from performing this action on github.com"
      end

      def raise_github_not_found_error
        raise GitHub::NotFound, "Resource could not be found on github.com"
      end

      def raise_github_server_error
        raise GitHub::Error, "There seems to be a problem on github.com, please try again."
      end

      def raise_github_too_many_requests(error)
        raise GitHub::Error, build_error_message(error)
      end

      def raise_github_unprocessable(error)
        raise GitHub::Error, build_error_message(error)
      end
    end
  end
end
