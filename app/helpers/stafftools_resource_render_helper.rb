module StafftoolsResourceRenderHelper
  def render_stafftools_resource_header(current_resource, previous_resource)
    return if (current_resource._data['_type'] == previous_resource._data['_type'])
    content_tag :h3, current_resource._data['_type'].capitalize.humanize.pluralize
  end

  def render_stafftools_resource(resource)
    type = resource._data['_type']
    render partial: "stafftools/#{type.pluralize}/#{type}", locals: { type.to_sym => resource }
  end
end
