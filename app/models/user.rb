# frozen_string_literal: true

class User < ApplicationRecord
  include Flippable
  include StafftoolsSearchable

  define_pg_search(columns: %i[id uid github_login github_name])

  has_many :assignment_repos
  has_many :repo_accesses, dependent: :destroy
  has_many :roster_entries
  has_many :invite_statuses, dependent: :destroy
  has_many :assignment_invitations, through: :invite_statuses

  has_and_belongs_to_many :organizations

  validates :last_active_at, presence: true

  validates :token, presence: true, uniqueness: true

  validates :uid, presence: true
  validates :uid, uniqueness: true

  before_save :ensure_no_token_scope_loss

  before_validation(on: :create) { ensure_last_active_at_presence }

  delegate :authorized_access_token?, to: :github_user

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
    @github_client ||= GitHubClassroom.github_client(access_token: token, auto_paginate: true)
  end

  def github_user
    @github_user ||= GitHubUser.new(github_client, uid, classroom_resource: self)
  end

  def github_client_scopes
    GitHub::Token.scopes(token, github_client)
  end

  def staff?
    site_admin
  end

  def api_token(exp = 5.minutes.from_now)
    MessageVerifier.encode({ user_id: id }, exp)
  end

  def token=(value)
    encrypted_value = encrypt_value(value)
    super(encrypted_value)
  end

  def token
    decrypt_value(super)
  end

  def token_was
    decrypt_value(super)
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

  # Internal: Returns a SimpleBox encryptor for token encryption/decryption.
  def encryptor
    token_secret = Rails.application.secrets.token_secret
    raise "TOKEN_SECRET is not set, please check you .env file" if token_secret.blank?
    @encryptor ||= RbNaCl::SimpleBox.from_secret_key(token_secret.unpack("m0").first)
  end

  def encrypt_value(value)
    return if value.blank?

    ciphertext = encryptor.encrypt(value)
    hex = ciphertext.bytes.pack("c*").unpack("H*").first
    "GH_" + hex
  end

  def decrypt_value(value)
    return value unless value && value =~ /\AGH_/

    hex = value.sub(/\AGH_/, '')
    encryptor.decrypt([hex].pack("H*")).force_encoding(Encoding::UTF_8)
  end
end
