# frozen_string_literal: true

module DockerCompose
  class Services
    include Enumerable

    attr_accessor :services

    def initialize(*services)
      @services = services
    end

    def each(&block)
      @services.each(&block)
    end

    def <<(service)
      @services << service
    end

    def up?(names)
      return false if @services.empty?

      requested_services = @services.find_all do |service|
        names.include?(service.name)
      end

      !requested_services.map(&:up?).include?(false)
    end
  end
end
