# frozen_string_literal: true

module GitHubClassroom
  module LTI
    class ConfigurationBuilder
      def initialize(title, launch_url)
        @configuration = IMS::LTI::Services::ToolConfig.new(title: title, launch_url: launch_url)
      end

      def to_xml
        @configuration.to_xml
      end

      def add_attributes(options = {})
        options.each_pair do |key, val|
          @configuration.send("#{key}=", val) if @configuration.respond_to?("#{key}=")
        end

        self
      end

      def add_vendor_attributes(vendor, ext = {})
        ext.each_pair do |key, val|
          @configuration.set_ext_param(vendor, key, val)
        end

        self
      end
    end
  end
end
