require 'rspec/rails'
require 'vcr'

VCR.configure do |config|
  config.configure_rspec_metadata!

  config.cassette_library_dir = 'spec/support/cassettes'

  config.default_cassette_options = {
    serialize_with: :json,
    preserve_exact_body_bytes:  true,
    decode_compressed_response: true
  }

  config.filter_sensitive_data('<<OWNER_ACCESS_TOKEN>>') do
    classroom_owner_github_token
  end

  config.filter_sensitive_data('<<STUDENT_ACCESS_TOKEN>>') do
    classroom_student_github_token
  end

  config.hook_into :webmock
end

def classroom_owner
  ENV.fetch 'CLASSROOM_OWNER', 'owner'
end

def classroom_owner_id
  (ENV.fetch 'CLASSROOM_OWNER_ID', 8_675_309).to_i
end

def classroom_owner_github_token
  ENV.fetch 'CLASSROOM_OWNER_GITHUB_TOKEN', 'x' * 40
end

def classroom_student
  ENV.fetch 'CLASSROOM_STUDENT', 'student'
end

def classroom_student_id
  (ENV.fetch 'CLASSROOM_STUDENT_ID', 8_675_301).to_i
end

def classroom_student_github_token
  ENV.fetch 'CLASSROOM_STUDENT_GITHUB_TOKEN', 'x' * 40
end

def member_github_organization
  ENV.fetch 'CLASSROOM_MEMBER_ORGANIZATION', 'member'
end

def oauth_client
  Octokit::Client.new(access_token: classroom_owner_github_token)
end

def classroom_owner_github_org
  ENV.fetch 'CLASSROOM_OWNER_ORGANIZATION', 'owner-org'
end

def classroom_owner_github_org_id
  (ENV.fetch 'CLASSROOM_OWNER_ORGANIZATION_ID', 276_350_626).to_i
end

def use_vcr_placeholder_for(text, replacement)
  VCR.configure do |c|
    c.define_cassette_placeholder(replacement) do
      text
    end
  end
end
