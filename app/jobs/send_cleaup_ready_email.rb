# frozen_string_literal: true

class SendCleanupReadyEmail < ApplicationJob
  queue_as :default

  def perform
    CleanupReadyMailer.ready('samuelvaneck@gmail.com').deliver
  end
end
