# frozen_string_literal: true
module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation do
      slugify
    end
  end

  def slugify
    return if self.slug.present?
    self.slug = title.parameterize
  end

  def to_param
    slug
  end
end
