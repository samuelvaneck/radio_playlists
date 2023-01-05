# frozen_string_literal: true

require 'csv'

class CleanUpJob < ApplicationJob
  queue_as :default

  def perform
    FileUtils.mkdir_p(Rails.root.join('tmp/recognizer_logs'))
    file = Rails.root.join('tmp', 'recognizer_logs', "recognizer_logs_#{1.day.ago.strftime('%F')}.csv")
    out_dated_logs = SongRecognizerLog.outdated

    CSV.open(file, 'w') do |writer|
      writer << out_dated_logs.first.attributes.map { |colunm_name, _value| colunm_name }
      out_dated_logs.each do |log|
        writer << log.attributes.map { |_colunm_name, value| value }
      end
    end

    out_dated_logs.delete_all
  end
end
