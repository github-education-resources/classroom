# frozen_string_literal: true

module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :slugify
  end

  def slugify
    set_slug
  end

  def to_param
    slug
  end

  private

  def name_for_slug
    title
  end

  def set_slug
    count = 1

    # slice to 2 below the database limit for -1, -2, etc
    self.slug = (escape_url(name_for_slug).presence || id.to_s).slice(0, 253)

    until unique_slug?
      self.slug = slug.gsub(/\-\d+$/, "") + "-#{count}"
      count += 1
    end
  end

  def unique_slug_criteria
    criteria = self.class.where(slug: slug)
    criteria = criteria.where("id <> ?", id) if persisted?
    criteria
  end

  def unique_slug?
    !unique_slug_criteria.exists?
  end

  def escape_url(str)
    return if str.nil?
    str.to_s.parameterize
  end
end
