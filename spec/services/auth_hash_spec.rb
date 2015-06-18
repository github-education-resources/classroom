require 'rails_helper'

describe AuthHash do
  it 'extracts the users information' do
    auth = AuthHash.new(OmniAuth.config.mock_auth[:github])
    expect(auth.user_info[:token]).to eq('some-token')
  end
end
