# frozen_string_literal: true

module StafftoolsResourceRenderHelper
  def render_stafftools_resource(resource)
    type = resource.class.to_s.underscore.downcase
    render partial: "stafftools/#{type.pluralize}/#{type}", locals: { type.to_sym => resource }
  end
end
