# frozen_string_literal: true

# Converts from Deadline to string representing datetime in correct format for forms
module DeadlineFormatHelper
  def self.convert(deadline)
    deadline ? deadline.deadline_at.strftime("%m/%d/%Y %H:%M") : ""
  end
end
