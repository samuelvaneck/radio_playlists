# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SendStatusEmail do
  include ActiveJob::TestHelper
  let(:radiostation) { FactoryBot.create :radiostation }
  let(:playlist) { FactoryBot.create :generalplaylists, radiostation: radiostation }

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
