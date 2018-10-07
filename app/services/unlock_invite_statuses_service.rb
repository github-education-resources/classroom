# frozen_string_literal: true

module UnlockInviteStatusesService
  INVITE_STATUS_MODELS = [InviteStatus, GroupInviteStatus].freeze
  TIME = 1.hour

  class << self
    # rubocop:disable MethodLength
    def unlock_invite_statuses
      stat_map = create_stat_map
      each_invite_status do |invite_status_model, invite_status|
        model_name = invite_status_model.to_s.underscore
        old_status = invite_status.status
        last_updated_at = invite_status.updated_at
        next unless invite_status.unlock_if_locked!(elapsed_locked_time: TIME)
        stat_map[model_name][old_status] += 1
        stat_map["total_#{model_name.pluralize}"] += 1
        report_to_failbot(model_name, old_status, last_updated_at, invite_status)
      end
      stat_map
    end
    # rubocop:enable MethodLength

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

    def report_to_failbot(model_name, old_status, last_updated_at, invite_status)
      raise StandardError, "An #{model_name} was locked for too long and needed to be unlocked"
    rescue StandardError => error
      other_context = {
        old_status: old_status,
        last_updated_at: last_updated_at
      }
      other_context[model_name.to_sym] = invite_status
      Failbot.report!(error, other_context)
    end
  end
end
