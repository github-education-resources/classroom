module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation do
      slugify
    end

    validates :slug, presence: true
  end

  def slugify
    self.slug = title.parameterize
  end

  def to_param
    slug
  end
end
