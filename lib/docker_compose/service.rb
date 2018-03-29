# frozen_string_literal: true

module DockerCompose
  class Service
    attr_reader :name, :command, :state, :port

    def initialize(name:, command:, state:, ports:)
      @name    = name
      @command = command
      @state   = state
      @ports   = ports
    end

    def up?
      state == "Up"
    end
  end
end
