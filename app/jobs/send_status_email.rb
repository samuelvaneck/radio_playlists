# frozen_string_literal: true

class SendStatusEmail < ApplicationJob
  queue_as :default

  def perform
    results = {
      radio_1: Radiostation.find_by(name: 'Radio 1').status,
      radio_2: Radiostation.find_by(name: 'Radio 2').status,
      radio_3fm: Radiostation.find_by(name: 'Radio 3FM').status,
      radio_4: Radiostation.find_by(name: 'Radio 4').status,
      radio_5: Radiostation.find_by(name: 'Radio 5').status,
      sky_radio: Radiostation.find_by(name: 'Sky Radio').status,
      radio_veronica: Radiostation.find_by(name: 'Radio Veronica').status,
      radio_538: Radiostation.find_by(name: 'Radio 538').status,
      radio_10: Radiostation.find_by(name: 'Radio 10').status,
      q_music: Radiostation.find_by(name: 'Qmusic').status,
      sublime_fm: Radiostation.find_by(name: 'Sublime FM').status,
      groot_nieuw_radio: Radiostation.find_by(name: 'Groot Nieuws Radio').status
    }

    StatusMailer.status_mail('samuelvaneck@gmail.com', results).deliver
  end
end
