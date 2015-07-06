class User < ActiveRecord::Base
  has_many :repo_accesses, dependent: :destroy

  has_and_belongs_to_many :organizations

  validates :uid, :token, presence: true
  validates :uid, :token, uniqueness: true

  def assign_from_auth_hash(hash)
    update_attributes(AuthHash.new(hash).user_info)
  end

  def self.create_from_auth_hash(hash)
    create!(AuthHash.new(hash).user_info)
  end

  def self.find_by_auth_hash(hash)
    conditions = AuthHash.new(hash).user_info.slice(:uid)
    find_by(conditions)
  end

  def github_client
    @github_client ||= Octokit::Client.new(access_token: token, auto_paginate: true)
  end

  def github_login
    github_client.user.login
  end
end
