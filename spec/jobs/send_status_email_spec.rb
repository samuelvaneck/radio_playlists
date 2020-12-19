# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SendStatusEmail do
  include ActiveJob::TestHelper
  let!(:radio_station) { FactoryBot.create :radiostation }
  let!(:radio_station_two) { FactoryBot.create :radiostation }
  let!(:radio_station_three) { FactoryBot.create :radiostation }
  let!(:radio_station_four) { FactoryBot.create :radiostation }
  let!(:playlist) { FactoryBot.create :generalplaylist, :filled, radiostation: radio_station }
  let!(:playlist_two) { FactoryBot.create :generalplaylist, :filled, radiostation: radio_station_two }
  let!(:playlist_three) { FactoryBot.create :generalplaylist, :filled, radiostation: radio_station_three }
  let!(:playlist_four) { FactoryBot.create :generalplaylist, :filled, radiostation: radio_station_four, created_at: 6.hours.ago }

  describe '#perform' do
    it 'creates a job' do
      ActiveJob::Base.queue_adapter = :test
      expect {
        described_class.perform_later
      }.to have_enqueued_job.on_queue('default')
    end

    it 'send the status email' do
      expect {
        perform_enqueued_jobs do
          described_class.perform_later
        end
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it 'sends the email to the right user' do
      perform_enqueued_jobs do
        described_class.perform_later
      end

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to[0]).to eq 'samuelvaneck@gmail.com'
    end
  end
end
