# frozen_string_literal: true

module MarkdownRenderHelper
  def markdown(text)
    doc = Kramdown::Document.new(text)
    return doc.to_html.html_safe
  end
end
