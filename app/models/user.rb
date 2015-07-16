class User < ActiveRecord::Base
  enum status: [:active, :pending]

  has_many :groups,        through:   :repo_accesses
  has_many :repo_accesses, dependent: :destroy

  has_and_belongs_to_many :organizations

  validates :status, presence: true

  validates :token, presence:   true, if: :active?
  validates :token, uniqueness: true, allow_blank: true, if: :pending?

  validates :uid, presence:   true
  validates :uid, uniqueness: true

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
