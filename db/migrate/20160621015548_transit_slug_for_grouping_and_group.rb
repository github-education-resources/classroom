class TransitSlugForGroupingAndGroup < ActiveRecord::Migration
  def up
    Grouping.all.each do |grouping|
      slug = grouping.slugify
      suffix_number = 0
      loop do
        break unless Grouping.where(slug: suffixed_slug(slug, suffix_number), organization: grouping.organization).present?
        suffix_number += 1
      end

      grouping.slug = suffixed_slug(slug, suffix_number)
      grouping.save!(validate: false)
    end

    Group.all.each do |group|
      group.slugify
      group.save!
    end
  end

  private

  def suffixed_slug(slug, suffix_number)
    return "#{slug}" if suffix_number.zero?
    "#{slug}-#{suffix_number}"
  end
end
