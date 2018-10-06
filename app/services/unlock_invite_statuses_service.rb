# frozen_string_literal: true

module UnlockInviteStatusesService
  INVITE_STATUS_MODELS = [InviteStatus, GroupInviteStatus].freeze
  TIME = 1.hour

  class << self
    def unlock_invite_statuses
      stat_map = create_stat_map
      each_invite_status do |invite_status_model, invite_status|
        model_name = invite_status_model.to_s.underscore
        old_status = invite_status.status
        last_updated_at = invite_status.updated_at
        if invite_status.unlock_if_locked!(elapsed_locked_time: TIME)
          stat_map[model_name][old_status] += 1
          stat_map["total_#{model_name.pluralize}"] += 1
          # TODO: use last_updated_at with failbot
        end
      end
      stat_map
    end

    private

    def create_stat_map
      stats = {}
      INVITE_STATUS_MODELS.each do |invite_status_model|
        model_name = invite_status_model.to_s.underscore
        stats[model_name] = {}
        stats["total_#{model_name.pluralize}"] = 0
        SetupStatus::LOCKED_STATUSES.each do |status, _|
          stats[model_name][status] = 0
        end
      end
      stats
    end

    def each_invite_status
      INVITE_STATUS_MODELS.each do |invite_status_model|
        invite_status_model
          .where(status: invite_status_model::LOCKED_STATUSES)
          .find_in_batches(batch_size: 100) do |invite_statuses|
            invite_statuses.each do |invite_status|
              yield(invite_status_model, invite_status)
            end
          end
      end
    end
  end
end
