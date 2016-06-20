class AddSlugToGroupingsAndGroups < ActiveRecord::Migration

  def suffixed_slug(slug, suffix_number)
    return "#{slug}" if suffix_number.zero?
    "#{slug}-#{suffix_number}"
  end

  def up
    add_column :groupings, :slug, :string
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
    change_column :groupings, :slug, :string, null: false
    add_index     :groupings, :slug

    add_column :groups, :slug, :string
    Group.all.each do |group|
      group.slugify
      group.save!
    end
    change_column :groups, :slug, :string, null: false
    add_index     :groups, :slug
  end

  def down
    remove_column :groupings, :slug
    remove_column :groups, :slug
  end
end
