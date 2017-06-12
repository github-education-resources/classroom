# frozen_string_literal: true

class Deadline < ApplicationRecord
  belongs_to :assignment, polymorphic: true
  validates :deadline_at, presence: true
  validate :deadline_in_future

  def create_job
    DeadlineJob.set(wait_until: deadline_at).perform_later(id)
  end

  def passed?
    deadline_at.past?
  end

  private

  def deadline_in_future
    errors.add(:deadline_at, 'must be in the future') if deadline_at && deadline_at < Time.zone.now
  end
end
