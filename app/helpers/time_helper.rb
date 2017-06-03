# frozen_string_literal: true

module TimeHelper
  # Public: Create a local-time HTML element.
  #
  # Example:
  #
  #   <%= local_time(user.created_at) %>
  #   #=> <local-time datatime="">...</local-time>
  def local_time(time)
    options = {
      datetime: time.utc.iso8601,
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    }

    content_tag(:'local-time', time.strftime('%b %-d, %Y'), options)
  end
end
