# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require ::File.expand_path("../config/environment", __FILE__)

# use Rack::CanonicalHost, ENV["CANONICAL_HOST"] if ENV["CANONICAL_HOST"]
run Rails.application
