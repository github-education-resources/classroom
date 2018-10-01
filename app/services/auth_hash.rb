# frozen_string_literal: true

class AuthHash
  def self.extract_user_info(hash)
    AuthHash.new(hash).user_info
  end

  def initialize(user_hash)
    @user_hash = user_hash
  end

  def user_info
    {
      uid:        uid,
      token:      token,
      site_admin: site_admin,
      github_global_relay_id: node_id
    }
  end

  private

  attr_reader :user_hash

  def uid
    user_hash.fetch("uid")
  end

  def token
    user_hash.fetch("credentials") { {} }.fetch("token")
  end

  def site_admin
    return true if non_staff_github_admins_ids.include?(uid)
    raw_info[:site_admin]
  end

  def node_id
    raw_info[:node_id]
  end

  def non_staff_github_admins_ids
    return [] if ENV["NON_STAFF_GITHUB_ADMIN_IDS"].blank?
    ENV["NON_STAFF_GITHUB_ADMIN_IDS"].split(",").compact.delete_if(&:empty?)
  end

  def raw_info
    user_hash.fetch("extra") { {} }.fetch("raw_info") { {} }
  end
end
