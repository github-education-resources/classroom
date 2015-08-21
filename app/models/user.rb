class User < ActiveRecord::Base
  enum state: [:active, :pending]

  has_many :repo_accesses, dependent: :destroy

  has_and_belongs_to_many :organizations

  validates :token, presence: true, if: :active?
  validates :token, uniqueness: true, allow_blank: true, if: :pending?

  validates :uid, presence: true
  validates :uid, uniqueness: true

  def assign_from_auth_hash(hash)
    user_attributes = AuthHash.new(hash).user_info.merge(state: 'active')
    update_attributes(user_attributes)
  end

  def avatar_url(size = 80)
    "https://avatars.githubusercontent.com/u/#{uid}?v=3&size=#{size}"
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
    github_user.login
  end

  def github_url
    github_user.user.html_url
  end

  def staff?
    site_admin
  end

  private

  def github_user
    @github_user ||= GitHubUser.new(github_client)
  end
end
