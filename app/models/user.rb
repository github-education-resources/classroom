# frozen_string_literal: true
class User < ActiveRecord::Base
  include Flippable

  update_index('stafftools#user') { self }

  has_many :repo_accesses, dependent: :destroy
  has_many :assignment_repos

  has_and_belongs_to_many :organizations

  validates :last_active_at, presence: true

  validates :token, presence: true, uniqueness: true

  validates :uid, presence: true
  validates :uid, uniqueness: true

  before_save :ensure_no_token_scope_loss

  before_validation(on: :create) { ensure_last_active_at_presence }

  def assign_from_auth_hash(hash)
    user_attributes = AuthHash.new(hash).user_info
    update_attributes(user_attributes)
  end

  def authorized_access_token?
    github_user.authorized_access_token?
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

  def github_client_scopes
    GitHub::Token.scopes(token, github_client)
  end

  def staff?
    site_admin
  end

  def identifier(type)
    StudentIdentifier.find_by(user: self, student_identifier_type: type)
  end

  # This updates the `last_active_at` column without
  # updating the model, but keeps the index updated.
  def become_active
    update_columns(last_active_at: Time.zone.now)
    self.class.update_index('stafftools#user') { self }
  end

  private

  # Internal: We need to make sure that the user
  # doesn't reduce the scope of their token. In
  # the event that their token is needed to
  # perform other functions.
  #
  # If the token that is trying to be set is
  # lower than the one we have toss it, and use the one we have.
  #
  # If the token has the same scopes but is newer, or has more scopes
  # let the token be set.
  #
  # See https://github.com/education/classroom/issues/445
  def ensure_no_token_scope_loss
    return true if token_was.blank?
    return true unless token_changed?

    old_scopes = GitHub::Token.scopes(token_was)
    new_scopes = GitHub::Token.scopes(token)

    # This is naive, if the token scopes ever change
    # come back an revist this.
    return true if old_scopes.size < new_scopes.size

    self.token = token_was
  end

  def ensure_last_active_at_presence
    self.last_active_at ||= Time.zone.now
  end
end
