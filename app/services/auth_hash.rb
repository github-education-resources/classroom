class AuthHash
  def self.extract_user_info(hash)
    AuthHash.new(hash).user_info
  end

  def initialize(user_hash)
    @user_hash = user_hash
  end

  def user_info
    {
      uid:      uid,
      login:    nickname,
      email:    email,
      name:     name,
      token:    token
    }
  end

  private

  attr_reader :user_hash

  def uid
    user_hash.fetch('uid')
  end

  def nickname
    info.fetch('nickname')
  end

  def email
    info.fetch('email', nil)
  end

  def name
    raw_info.fetch('name', nil)
  end

  def token
    user_hash.fetch('credentials', {}).fetch('token')
  end

  private

  def info
    user_hash.fetch('info', {})
  end

  def raw_info
    user_hash.fetch('extra', {}).fetch('raw_info', {})
  end
end
