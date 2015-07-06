require 'rspec/rails'

VCR.configure do |c|
  c.configure_rspec_metadata!

  c.cassette_library_dir = 'spec/support/cassettes'

  c.default_cassette_options = {
    serialize_with: :json,
    preserve_exact_body_bytes:  true,
    decode_compressed_response: true,
    record: ENV['TRAVIS'] ? :none : :once
  }

  c.filter_sensitive_data('<CLASSROOM_OWNER_ACCESS_TOKEN>') do
    classroom_owner_github_token
  end

  c.filter_sensitive_data('<CLASSROOM_STUDENT_GITHUB_TOKEN>') do
    classroom_student_github_token
  end

  c.hook_into :webmock
end

def classroom_owner_github_token
  ENV.fetch 'CLASSROOM_OWNER_GITHUB_TOKEN', 'x' * 40
end

def classroom_student_github_token
  ENV.fetch 'CLASSROOM_STUDENT_GITHUB_TOKEN', 'q' * 40
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
