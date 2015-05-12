class User < ActiveRecord::Base
  def self.create_from_auth_hash(hash)
    create!(AuthHash.new(hash).user_info)
  end

  def assign_from_auth_hash(hash)
    update_attributes(AuthHash.new(hash).user_info)
  end

  def self.find_by_auth_hash(hash)
    conditions = AuthHash.new(hash).user_info.slice(:provider, :uid)
    where(conditions).first
  end
end
