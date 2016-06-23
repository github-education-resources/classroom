class TransitSlugForGroupingAndGroup < ActiveRecord::Migration
  def up
    %w(Grouping Group).each do |model|
      klass = model.constantize

      klass.includes(:organization).all.each do |g|
        slug = g.slugify
        suffix_number = 0

        loop do
          break unless klass.where(slug: suffixed_slug(slug, suffix_number), organization: g.organization).present?
          suffix_number += 1
        end

        g.slug = suffixed_slug(slug, suffix_number)
        g.save!(validate: false)
      end
    end
  end

  private

  def suffixed_slug(slug, suffix_number)
    return "#{slug}" if suffix_number.zero?
    "#{slug}-#{suffix_number}"
  end
end
