# frozen_string_literal: true

module SetupStatus
  extend ActiveSupport::Concern

  ERRORED_STATUSES = %w[errored_creating_repo errored_importing_starter_code].freeze
  LOCKED_STATUSES = %w[waiting creating_repo importing_starter_code].freeze
  SETUP_STATUSES = %w[accepted waiting creating_repo importing_starter_code].freeze

  included do
    enum status: {
      unaccepted:                     0,
      accepted:                       1,
      waiting:                        2,
      creating_repo:                  3,
      importing_starter_code:         4,
      completed:                      5,
      errored_creating_repo:          6,
      errored_importing_starter_code: 7
    }
  end

  def errored?
    ERRORED_STATUSES.include?(status)
  end

  def setting_up?
    SETUP_STATUSES.include?(status)
  end

  def locked?
    LOCKED_STATUSES.include?(status)
  end
end
