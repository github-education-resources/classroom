require 'github/markup'

class Note
  attr_reader :slug

  class << self
    def all
      all_slugs.map { |slug| new(slug) }.sort
    end

    def find(slug)
      all.detect { |note| note.slug == slug }
    end

    def directory
      Rails.root.join('app', 'views', 'stafftools', 'notes').to_s
    end

    private

    def all_slugs
      @all_slugs ||= Dir.glob("#{directory}/*.md").map { |f| File.basename(f).sub(/\.md$/, '') }
    end
  end

  def initialize(slug)
    @slug = slug
  end

  def title
    slug.titleize
  end

  def html
    to_html
  end

  def to_param
    slug
  end

  def <=>(other)
    other.title <=> title
  end

  private

  def file_path
    "#{self.class.directory}/#{slug}.md"
  end

  def to_html
    GitHub::Markup.render(file_path, File.read(file_path)).html_safe
  end
end
