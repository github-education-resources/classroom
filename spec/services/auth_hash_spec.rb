# frozen_string_literal: true

require "rails_helper"

describe AuthHash do
  let(:auth_hash) { AuthHash.new(OmniAuth.config.mock_auth[:github]) }

  describe "#extract_user_info" do
    it "extracts the users information" do
      expect(auth_hash.user_info[:token]).to eq(OmniAuth.config.mock_auth[:github]["credentials"]["token"])
    end
  end

  describe "#non_staff_github_admins_ids" do
    it "returns an empty array if there the ENV is not set" do
      ENV["NON_STAFF_GITHUB_ADMIN_IDS"] = nil
      expect(auth_hash.instance_eval { non_staff_github_admins_ids }).to eql([])
    end

    it "returns only one id" do
      ENV["NON_STAFF_GITHUB_ADMIN_IDS"] = ",,1"
      expect(auth_hash.instance_eval { non_staff_github_admins_ids }).to eql(["1"])
    end

    it "returns multiple ids" do
      ENV["NON_STAFF_GITHUB_ADMIN_IDS"] = "1,2,3"
      expect(auth_hash.instance_eval { non_staff_github_admins_ids }).to eql(%w[1 2 3])
    end
  end
end
