class NullGitHubResource
  def initialize
    set_null_github_attributes
  end

  def null?
    true
  end

  private

  def set_null_github_attributes
    null_github_user_attributes.each do |attr, value|
      define_singleton_method(attr) { value }
    end
  end
end
