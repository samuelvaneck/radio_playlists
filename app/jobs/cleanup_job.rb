class CleanupJob < ApplicationJob
  queue_as :default

  def perform
    Generalplaylist.all.each(&:deduplicate)
    Song.all.each(&:cleanup)
    Artist.all.each(&:cleanup)

    SendCleanupReadyEmail.perform_later
  end
end
