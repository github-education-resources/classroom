# frozen_string_literal: true

module DockerCompose
  class Parser
    # Public: Parse the docker-compose output and get the services
    #
    # output - The String output results from `docker-compose ps`
    #
    # rubocop:disable Metrics/LineLength
    # Examples:
    #
    #   output = `docker-compose ps`
    #   pp output
    #
    # "         Name                        Command               State                         Ports                       \n" +
    # "---------------------------------------------------------------------------------------------------------------------\n" +
    # "classroom_elasticsearch   /docker-entrypoint.sh elas ...   Up      127.0.0.1:9227->9200/tcp, 127.0.0.1:9337->9300/tcp\n" +
    # "classroom_memcached       docker-entrypoint.sh memcached   Up      127.0.0.1:22322->11211/tcp                        \n" +
    # "classroom_postgresql      /docker-entrypoint.sh postgres   Up      127.0.0.1:2345->5432/tcp                          \n" +
    # "classroom_redis           docker-entrypoint.sh redis ...   Up      127.0.0.1:9736->6379/tcp                          \n"
    #
    #   DockerCompose::Parser.parse(output)
    #   # => #<DockerCompose::Services:0x00007fddea842ef0
    #         @services=
    #          [#<DockerCompose::Service:0x00007fddea842c48
    #            @command="docker-entrypoint.sh postgres",
    #            @name="classroom_postgresql",
    #            @ports="127.0.0.1:2345->5432/tcp",
    #            @state="Up">]>
    #
    # rubocop:enable Metrics/LineLength
    #
    # Returns an instance of DockerCompose::Services.
    def self.parse(output)
      services = DockerCompose::Services.new

      output.split("\n")[2..-1].map do |service|
        services << DockerCompose::Service.new(**service_attributes(service))
      end

      services
    end

    def self.service_attributes(service)
      attributes = service.split(" ")

      # Grab everything that starts with a number
      # which I'm going to assume is a port.
      ports = []
      while attributes[-1][0].match?(/\d/)
        ports.unshift(attributes[-1])
        attributes.pop
      end

      state   = attributes.pop
      name    = attributes.shift
      command = attributes.join(" ")

      { name: name, command: command, state: state, ports: ports.join(" ").to_s }
    end

    private_class_method :service_attributes
  end
end
