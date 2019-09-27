# frozen_string_literal: true

class Deadline
  class Factory
    DATETIME_FORMAT = "%m/%d/%Y %H:%M %z"

    # Accepts an optional datetime format string :datetime_format
    # Default DateTime format is %m/%d/%Y %H:%M %z
    # e.g. 05/25/2017 13:17-0800
    def self.build_from_string(opts = {})
      deadline = Deadline.new

      format = opts[:datetime_format] || DATETIME_FORMAT
      deadline.deadline_at = DateTime.strptime(opts[:deadline_at], format) if opts[:deadline_at]

      deadline
    rescue ArgumentError
      deadline.errors.add(:deadline_at, "not formatted correctly.") && deadline
    end
  end
end
