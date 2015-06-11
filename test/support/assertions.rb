require 'minitest/assertions'

module Minitest
  module Assertions
    def assert_matching_interface(expected, actual)
      missing_methods_array = missing_methods(expected, actual)
      assert_empty missing_methods_array, "Expected #{actual.inspect} to respond to #{missing_methods_array.join(', ')}"
    end

    private

    def missing_methods(expected, actual)
      expected_methods(expected) - actual_methods(actual) - common_methods
    end

    def expected_methods(expected)
      expected.instance_methods
    end

    def actual_methods(actual)
      actual.instance_methods
    end

    def common_methods
      Object.instance_methods
    end
  end
end
