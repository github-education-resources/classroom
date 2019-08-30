# frozen_string_literal: true

class AddStudentsToRosterJob < ApplicationJob
  queue_as :roster

  ROSTER_UPDATE_SUCCESSFUL = "Roster successfully updated."
  ROSTER_UPDATE_FAILED     = "Could not add any students to roster, please try again."
  ROSTER_UPDATE_PARTIAL_SUCCESS = "Could not add following students:"

  # Takes an array of identifiers and creates a
  # roster entry for each. Omits duplicates, and
  #
  # rubocop:disable AbcSize
  # rubocop:disable MethodLength
  def perform(identifiers, roster, user, lms_user_ids = [])
    channel = AddStudentsToRosterChannel.channel(roster_id: roster.id, user_id: user.id)
    # ActionCable.server.broadcast(channel, status: "update_started")

    identifiers = add_suffix_to_duplicates!(identifiers, roster)
    invalid_roster_entries =
      identifiers.zip(lms_user_ids).map do |identifier, lms_user_id|
        roster_entry = RosterEntry.create(identifier: identifier, roster: roster, lms_user_id: lms_user_id)
        roster_entry.identifier if roster_entry.errors.include?(:identifier)
      end.compact!

    message = build_message(invalid_roster_entries, identifiers)
    entries_created = identifiers.count - invalid_roster_entries.count
    if lms_user_ids.present? && entries_created.positive?
      GitHubClassroom.statsd.increment("roster_entries.lms_imported", by: entries_created)
    end
    ActionCable.server.broadcast(channel, message: message, status: "completed")
  end
  # rubocop:enable AbcSize
  # rubocop:enable MethodLength

  def add_suffix_to_duplicates!(identifiers, roster)
    existing_roster_entries = RosterEntry.where(roster: roster).pluck(:identifier)
    RosterEntry.add_suffix_to_duplicates(
      identifiers: identifiers,
      existing_roster_entries: existing_roster_entries
    )
  end

  # rubocop:disable MethodLength
  def build_message(invalid_roster_entries, identifiers)
    if invalid_roster_entries.empty?
      ROSTER_UPDATE_SUCCESSFUL
    elsif invalid_roster_entries.size == identifiers.size
      ROSTER_UPDATE_FAILED
    else
      formatted_students =
        invalid_roster_entries.map do |invalid_roster_entry|
          "#{invalid_roster_entry} \n"
        end.join("")
      "#{ROSTER_UPDATE_PARTIAL_SUCCESS} \n#{formatted_students}"
    end
  end
  # rubocop:enable MethodLength
end
