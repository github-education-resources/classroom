# frozen_string_literal: true

module MarkdownRenderHelper
  def markdown(text)
    doc = Kramdown::Document.new(text)
    doc.to_html
  end
end
