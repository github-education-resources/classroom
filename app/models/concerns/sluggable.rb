module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation do
      slugify
    end
  end

  def slugify
    self.slug = title.parameterize
  end
end
