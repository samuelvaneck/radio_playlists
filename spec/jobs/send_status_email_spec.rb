# frozen_string_literal: true

describe SendStatusEmail do
  include ActiveJob::TestHelper
  let!(:radio_station) { create :radio_station }
  let!(:radio_station_two) { create :radio_station }
  let!(:radio_station_three) { create :radio_station }
  let!(:radio_station_four) { create :radio_station }
  let!(:playlist) { create :playlist, :filled, radio_station: radio_station }
  let!(:playlist_two) { create :playlist, :filled, radio_station: radio_station_two }
  let!(:playlist_three) { create :playlist, :filled, radio_station: radio_station_three }
  let!(:playlist_four) { create :playlist, :filled, radio_station: radio_station_four, created_at: 6.hours.ago }

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
