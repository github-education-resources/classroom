# frozen_string_literal: true

class DeadlineIndex < Chewy::Index
  define_type Deadline do
    field :id
    field :deadline_at
    field :created_at
    field :updated_at
  end
end
