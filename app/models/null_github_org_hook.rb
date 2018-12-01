# frozen_string_literal: true

class NullGitHubOrgHook < NullGitHubResource
  def active
    false
  end

  def active?
    active
  end

  def name
    nil
  end

  def created_at
    nil
  end

  def updated_at
    nil
  end
end
