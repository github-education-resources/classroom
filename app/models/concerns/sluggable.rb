# frozen_string_literal: true

module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :slugify
  end

  def slugify
    self.slug = name_for_slug.parameterize
  end

  def to_param
    slug
  end

  private

  def name_for_slug
    title
  end
end
