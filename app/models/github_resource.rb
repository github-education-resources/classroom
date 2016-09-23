# frozen_string_literal: true
class GitHubResource
  attr_reader :id

  def initialize(client, id)
    @client = client
    @id     = id

    create_attribute_methods(client, id, attributes)
  end

  def access_token
    @client.access_token
  end

  def on_github?(options = {}) # rubocop:disable Metrics/MethodLength
    resource = begin
                 # rubocop:disable Lint/UnneededSplatExpansion
                 GitHub::Errors.with_error_handling { @client.send(github_type, *[@id, options]) }
               rescue GitHub::Error
                 begin
                   GitHub::Errors.with_error_handling do
                     GitHubClassroom.github_client.send(github_type, *[@id, options])
                   end
                 rescue GitHub::Error
                   nil
                 end
                 # rubocop:enable Lint/UnneededSplatExpansion
               end

    resource.present?
  end

  private

  # rubocop:disable MethodLength
  # rubocop:disable Metrics/AbcSize
  # Internal: create instance methods for a given list of attributes
  #
  # client - the Octokit::Client that will be used
  # id - The Integer that is the GitHub id for the resource
  # attributes - the Array of Symbols that will be generated into instance methods
  #
  # NOTE: This method has three layers to get the attribute from
  # the GitHub API. The client given to it, the application client
  # using the Classroom client_id and secret, and the NullGitHubObject
  # that it will fallback to if it is not possible to find it on GitHub.
  #
  # This allows us to perform actions such as
  #
  #   github_user.login
  #   #=> "tarebyte"
  #
  #   github_user.login(headers: GitHub::APIHeaders.no_cache_no_store)
  #   #=> "tarebyte"
  #
  # Without having to create each method.
  #
  # NOTE: This will memoize the resource after it's called for the first time.
  #
  # Returns nil.
  def create_attribute_methods(client, id, attributes)
    attributes.each { |attribute| instance_variable_set("@#{attribute}", nil) }

    attributes.each do |attribute|
      define_singleton_method(attribute) do |options = {}|
        return instance_variable_get('@' + attribute) if instance_variable_get('@' + attribute).present?

        value = begin
                  # rubocop:disable Lint/UnneededSplatExpansion
                  GitHub::Errors.with_error_handling { client.send(github_type, *[id, options])[attribute] }
                rescue GitHub::Error
                  begin
                    GitHub::Errors.with_error_handling do
                      GitHubClassroom.github_client.send(github_type, *[id, options])[attribute]
                    end
                  rescue GitHub::Error
                    null_github_object.send(attribute)
                  end
                  # rubocop:enable Lint/UnneededSplatExpansion
                end

        instance_variable_set('@' + attribute, value)
        value
      end
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable MethodLength

  # Internal
  def attributes
    []
  end

  # Internal
  # Example "GitHubUser" -> :user
  def github_type
    self.class.to_s.underscore.gsub(/github_/, '').to_sym
  end

  # Internal
  def null_github_object
    @null_github_object ||= Object.const_get("Null#{self.class}").new
  end
end
