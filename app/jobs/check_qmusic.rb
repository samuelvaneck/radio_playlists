# frozen_string_literal: true

class CheckQmusic < ApplicationJob
  queue_as :default

  def perform
    Generalplaylist.q_music_check
  end
end
