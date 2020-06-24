# frozen_string_literal: true

class MigratePlaylistTimeJob < ApplicationJob
  queue_as :default

  def perform
    Generalplaylist.find_in_batches do |group|
      group.each do |playlist|
        next if playlist.broadcast_timestamp.present?

        begin
          playlist.update(broadcast_timestamp: Time.parse(playlist.created_at.strftime('%F') + ' ' + playlist.time))
        rescue StandardError => _e
          playlist.update(broadcast_timestamp: playlist.created_at)
        end
      end
    end
  end
end
