# frozen_string_literal: true

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

  def to_param
    slug
  end
end
