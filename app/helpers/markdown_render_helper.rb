# frozen_string_literal: true

module MarkdownRenderHelper
  def markdown(text)
    md = Redcarpet::Markdown.new(Redcarpet::Render::HTML,
      no_intra_emphasis: true,
      fenced_code_blocks: true,
      disable_indented_code_blocks: true)
    return md.render(text).html_safe
  end
end
