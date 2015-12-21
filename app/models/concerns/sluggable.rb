module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation do
      slugify
    end
  end

  def slugify
    self.slug = title.to_slug.normalize.to_s
  end

  def to_param
    slug
  end
end
