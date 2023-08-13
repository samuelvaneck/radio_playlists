# frozen_string_literal: true

require 'csv'

class CleanUpJob < ApplicationJob
  queue_as :default

  def perform
    create_recognizer_folder
    write_logs_to_csv_file
    delete_outdated_logs
  end

  private

  def create_recognizer_folder
    FileUtils.mkdir_p(Rails.root.join('tmp/recognizer_logs'))
  end

  def write_logs_to_csv_file
    CSV.open(csv_file, 'w') do |writer|
      writer << out_dated_logs.first.attributes.map { |column_name, _value| column_name }
      out_dated_logs.each do |log|
        writer << log.attributes.map { |_column_name, value| value }
      end
    end
  end

  def csv_file
    Rails.root.join('tmp', 'recognizer_logs', "recognizer_logs_#{Time.now.strftime('%F')}.csv")
  end

  def delete_outdated_logs
    out_dated_logs.delete_all
  end

  def out_dated_logs
    @out_dated_logs ||= SongRecognizerLog.outdated
  end
end
