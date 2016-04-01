class User < ActiveRecord::Base
  include Flippable

  update_index('stafftools#user') { self }

  has_many :repo_accesses, dependent: :destroy
  has_many :assignment_repos

  has_and_belongs_to_many :organizations

  validates :token, presence: true, uniqueness: true

  validates :uid, presence: true
  validates :uid, uniqueness: true

  def avatar_url(size = 40)
    "#{github_user.avatar_url}&size=#{size}"
  end

  def assign_from_auth_hash(hash)
    user_attributes = AuthHash.new(hash).user_info
    update_attributes(user_attributes)
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

  def github_user
    @github_user ||= GitHubUser.new(github_client, uid)
  end

  def staff?
    site_admin
  end
end
