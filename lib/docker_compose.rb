# frozen_string_literal: true

require_relative "docker_compose/parser.rb"
require_relative "docker_compose/service.rb"
require_relative "docker_compose/services.rb"
require "yaml"

module DockerCompose
  # Public: Determine if all docker-compose services are in the 'Up' state.
  #
  # Example:
  #
  #   DockerCompose.services_running?(services: ["classroom_postgresql"])
  #   # => false
  #
  # Returns a boolean.
  def self.services_up?(services: [])
    return false if services.empty?

    # Need to do a better job and not use ``
    docker_compose_services = DockerCompose::Parser.parse(`docker-compose ps`)
    docker_compose_services.up?(services)
  end

  # Public: Determine if all docker-compose services are in the 'Up' state.
  #
  # Example:
  #
  #   DockerCompose.all_services_up?
  #   # => false
  #
  # Returns a boolean.
  def self.all_services_up?
    compose_output = ::YAML.load_file(::File.expand_path("../docker-compose.yml", __dir__))
    container_names = compose_output["services"].each_value.map do |service_attributes|
      service_attributes["container_name"]
    end

    DockerCompose.services_up?(services: container_names)
  end
end
