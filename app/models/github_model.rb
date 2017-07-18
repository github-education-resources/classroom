# frozen_string_literal: true

# An optional superclass for github resource models. `GitHubModel` provides a
# consistent hash-based attributes initializer.

class GitHubModel
  # Public: Track each attr_reader added to GitHubModel subclasses.
  def self.attr_reader(*names)
    attr_initializable(*names)
    super
  end

  def self.attr_initializable(*names)
    attr_initializables.concat(names.map(&:to_sym) - [:attributes])
  end

  # Internal: An Array of Hash initializable attributes on this class.
  def self.attr_initializables
    @attr_initializables ||= (superclass <= GitHubModel ? superclass.attr_initializables.dup : [])
  end

  # Internal: The attributes used to initialize this instance.
  attr_reader :attributes

  # Public: Create a new instance, optionally providing a `Hash` of
  # `attributes`. Any attributes with the same name as an
  # `attr_reader` will be set as instance variables.
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable MethodLength
  def initialize(client, id)
    attributes = {}.tap do |attr|
      attr[:id]           = id
      attr[:client]       = client
      attr[:access_token] = client.access_token

      # Get all of the attributes, set their attr_reader
      # and set their value.
      github_attributes.each do |gh_attr|
        self.class.class_eval { attr_reader gh_attr.to_sym }
        attr[gh_attr.to_sym] = github_response(client, id).send(gh_attr)
      end

      remove_instance_variable("@response")
    end

    update(attributes || {})

    # Create our *_no_cache methods for each GitHubModel
    set_github_no_cache_methods(client, id)

    after_initialize if respond_to? :after_initialize
  end
  # rubocop:enable MethodLength
  # rubocop:enable Metrics/AbcSize

  # Internal: Update this instance's attribute instance variables with
  # new values.
  #
  # attributes - A Symbol-keyed Hash of new attribute values.
  #
  # Returns self.
  def update(attributes)
    (@attributes ||= {}).merge! attributes

    (self.class.attr_initializables & attributes.keys).each do |name|
      instance_variable_set :"@#{name}", attributes[name]
    end

    self
  end

  # Public: Run an non cached API request to make sure we get something back
  #
  # Returns true if the resource is found, otherwise false.
  def on_github?
    response = github_client_request(client, id, headers: GitHub::APIHeaders.no_cache_no_store)
    response ||= github_classroom_request(id, headers: GitHub::APIHeaders.no_cache_no_store)
    response.present?
  end

  private

  # Internal: Define specified *_no_cache methods
  #
  # client - The Octokit::Client making the request
  # id     - The Interger id for the resource
  #
  # Returns an Sawyer::Resource or a Null:GitHubObject
  def set_github_no_cache_methods(client, id)
    github_attributes.each do |gh_no_cache_attr|
      define_singleton_method("#{gh_no_cache_attr}_no_cache") do
        response = github_client_request(client, id, headers: GitHub::APIHeaders.no_cache_no_store)
        response ||= github_classroom_request(id, headers: GitHub::APIHeaders.no_cache_no_store)

        response.present? ? response.send(gh_no_cache_attr) : null_github_object.send(gh_no_cache_attr)
      end
    end
  end

  # Internal: Return a GitHub API Response for an resource.
  #
  # client - The Octokit::Client making the request.
  # id     - The Interger id for the resource.
  #
  # Returns an Sawyer::Resource or a Null:GitHubObject.
  def github_response(client, id)
    return @response if defined?(@response)
    @response = github_client_request(client, id) || github_classroom_request(id)
    @response ||= null_github_object
  end

  # Internal: Make a GitHub API request for a resource.
  #
  # client  - The Octokit::Client making the request.
  # id      - The Interger id of the resource on GitHub.
  # options - A Hash of options to pass (optional).
  #
  # Returns a Sawyer::Resource or raises and error.
  def github_client_request(client, id, **options)
    GitHub::Errors.with_error_handling { client.send(github_type, id, options) }
  rescue GitHub::Error
    nil
  end

  # Internal: Make a GitHub API request for a resource
  #
  # id      - The Interger id of the resource on GitHub
  # options - A Hash of options to pass (optional).
  #
  # Returns a Sawyer::Resource or nil if an error occured.
  def github_classroom_request(id, **options)
    GitHub::Errors.with_error_handling do
      GitHubClassroom.github_client.send(github_type, id, options)
    end
  rescue GitHub::Error
    nil
  end

  # Internal: Get the resource type for the model
  #
  # Example:
  #
  #   GitHubUser -> :user
  #
  # Returns a Symbol.
  def github_type
    self.class.to_s.underscore.gsub(/github_/, "").to_sym
  end

  # Internal: Determin the appropriate NullGitHubObject
  # for the GitHubResource.
  #
  # Returns a NullGitHubObject for the class.
  def null_github_object
    @null_github_object ||= Object.const_get("Null#{self.class}").new
  end
end
