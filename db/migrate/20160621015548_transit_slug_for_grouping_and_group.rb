class TransitSlugForGroupingAndGroup < ActiveRecord::Migration[4.2]
  def up
    slugify_all_groupings
    slugify_all_groups
  end

  private

  def slugify_all_groupings
    Grouping.includes(:organization).all.each do |grouping|
      slug = grouping.slugify
      suffix_number = 0

      loop do
        break unless Grouping.where(
          slug: suffixed_slug(slug, suffix_number),
          organization: grouping.organization
        ).present?

        suffix_number += 1
      end

      grouping.slug = suffixed_slug(slug, suffix_number)
      grouping.save!(validate: false)
    end
  end

  def slugify_all_groups
    Group.includes(:grouping).all.each do |group|
      slug = group.slugify
      suffix_number = 0

      loop do
        break unless Group.where(
          slug: suffixed_slug(slug, suffix_number),
          grouping: group.grouping
        ).present?

        suffix_number += 1
      end

      group.slug = suffixed_slug(slug, suffix_number)
      group.save!(validate: false)
    end
  end

  def suffixed_slug(slug, suffix_number)
    return "#{slug}" if suffix_number.zero?
    "#{slug}-#{suffix_number}"
  end
end
