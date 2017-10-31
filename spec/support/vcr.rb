# frozen_string_literal: true

require "rspec/rails"

VCR.configure do |c|
  c.configure_rspec_metadata!
  c.cassette_library_dir = "spec/support/cassettes"

  c.default_cassette_options = {
    serialize_with: :json,
    preserve_exact_body_bytes:  true,
    decode_compressed_response: true,
    record: ENV["TRAVIS"] ? :none : :once
  }

  c.before_record { |i| i.request.headers.delete "Authorization" }

  # Application id
  c.filter_sensitive_data("<TEST_APPLICATION_GITHUB_CLIENT_ID>") do
    application_github_client_id
  end

  c.filter_sensitive_data("<TEST_APPLICATION_GITHUB_CLIENT_SECRET>") do
    application_github_client_secret
  end

  # Owner
  c.filter_sensitive_data("<TEST_CLASSROOM_OWNER_GITHUB_ID>") do
    classroom_owner_github_id
  end

  # Owners Org
  c.filter_sensitive_data("<TEST_CLASSROOM_OWNER_ORGANIZATION_GITHUB_ID>") do
    classroom_owner_organization_github_id
  end

  c.filter_sensitive_data("<TEST_CLASSROOM_OWNER_ORGANIZATION_GITHUB_LOGIN>") do
    classroom_owner_organization_github_login
  end

  # Student
  c.filter_sensitive_data("<TEST_CLASSROOM_STUDENT_GITHUB_ID>") do
    classroom_student_github_id
  end

  c.hook_into :webmock
end

def application_github_client_id
  ENV.fetch("GITHUB_CLIENT_ID") { "i" * 20 }
end

def application_github_client_secret
  ENV.fetch("GITHUB_CLIENT_SECRET") { "r" * 20 }
end

def classroom_owner_github_id
  ENV.fetch("TEST_CLASSROOM_OWNER_GITHUB_ID") { 8_675_309 }
end

def classroom_owner_github_token
  ENV.fetch("TEST_CLASSROOM_OWNER_GITHUB_TOKEN") { "x" * 40 }
end

def classroom_owner_organization_github_id
  ENV.fetch("TEST_CLASSROOM_OWNER_ORGANIZATION_GITHUB_ID") { 1 }
end

def classroom_owner_organization_github_login
  ENV.fetch("TEST_CLASSROOM_OWNER_ORGANIZATION_GITHUB_LOGIN") { "classroom-testing-org" }
end

def classroom_student_github_id
  ENV.fetch("TEST_CLASSROOM_STUDENT_GITHUB_ID") { 42 }
end

def classroom_student_github_token
  ENV.fetch("TEST_CLASSROOM_STUDENT_GITHUB_TOKEN") { "q" * 40 }
end

def oauth_client
  Octokit::Client.new(access_token: classroom_owner_github_token)
end

def use_vcr_placeholder_for(text, replacement)
  VCR.configure do |c|
    c.define_cassette_placeholder(replacement) do
      text
    end
  end
end
