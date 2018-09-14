# frozen_string_literal: true

module I18nHelper
  include ActionView::Helpers::UrlHelper

  # Converts markdown links in strings to html links
  def parse_markdown_link(str, link_options = {})
    # Matches Markdown link syntax into text and link
    match = str.match(/\[(.*)\]\((.*)\)/)
    return str if match.blank?

    # rubocop:disable OutputSafety
    raw(match.pre_match + link_to(match[1], match[2], link_options) + match.post_match) if match.present?
    # rubocop:enable OutputSafety
  end
end
