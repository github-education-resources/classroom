class User < ActiveRecord::Base
  has_and_belongs_to_many :organizations

  has_many :invitations, dependent: :destroy
  has_many :repo_accesses

  validates_presence_of   :uid, :token
  validates_uniqueness_of :uid, :token

  def self.create_from_auth_hash(hash)
    create!(AuthHash.new(hash).user_info)
  end

  def assign_from_auth_hash(hash)
    update_attributes(AuthHash.new(hash).user_info)
  end

  def self.find_by_auth_hash(hash)
    conditions = AuthHash.new(hash).user_info.slice(:uid)
    where(conditions).first
  end

  def github_client
    @github_client ||= GitHubClient.new(token)
  end
end
