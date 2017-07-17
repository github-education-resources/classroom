# frozen_string_literal: true

module StafftoolsResourceRenderHelper
  def render_stafftools_resource(resource)
    type = resource._data["_type"]
    render partial: "stafftools/#{type.pluralize}/#{type}", locals: { type.to_sym => resource }
  end
end
