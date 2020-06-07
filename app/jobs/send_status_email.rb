# frozen_string_literal: true

class SendStatusEmail < ApplicationJob
  queue_as :default

  def perform
    results = {
      radio_1: Generalplaylist.radio_station_status(Radiostation.find_by(name: 'Radio 1')),
      radio_2: Generalplaylist.radio_station_status(Radiostation.find_by(name: 'Radio 2')),
      radio_3fm: Generalplaylist.radio_station_status(Radiostation.find_by(name: 'Radio 3FM')),
      radio_4: Generalplaylist.radio_station_status(Radiostation.find_by(name: 'Radio 4')),
      radio_5: Generalplaylist.radio_station_status(Radiostation.find_by(name: 'Radio 5')),
      sky_radio: Generalplaylist.radio_station_status(Radiostation.find_by(name: 'Sky Radio')),
      radio_veronica: Generalplaylist.radio_station_status(Radiostation.find_by(name: 'Radio Veronica')),
      radio_538: Generalplaylist.radio_station_status(Radiostation.find_by(name: 'Radio 538')),
      radio_10: Generalplaylist.radio_station_status(Radiostation.find_by(name: 'Radio 10')),
      q_music: Generalplaylist.radio_station_status(Radiostation.find_by(name: 'Qmusic')),
      sublime_fm: Generalplaylist.radio_station_status(Radiostation.find_by(name: 'Sublime FM')),
      groot_nieuw_radio: Generalplaylist.radio_station_status(Radiostation.find_by(name: 'Groot Nieuws Radio')),
    }

    StatusMailer.send_email('samuelvaneck@gmail.com', results).deliver
  end
end
