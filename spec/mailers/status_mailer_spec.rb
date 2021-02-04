# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StatusMailer, type: :mailer do
  let(:radio_station) { FactoryBot.create :radiostation }
  let(:playlist) { FactoryBot.create :generalplaylist, :filled, radiostation: radio_station }
  let(:status_mail) { StatusMailer.status_mail('test@test.com', results) }
  let(:results) { { "#{radio_station.name}": radio_station.status } }

  before { playlist }

  describe 'status_mail' do
    it 'renders the headers' do
      expect(status_mail.subject).to eq 'Status radiostation playlists'
      expect(status_mail.to).to eq ['test@test.com']
      expect(status_mail.from).to eq ['radioplaylists@samuelvaneck.com']
    end

    it 'renders the email body' do
      expect(status_mail.body.encoded).to match 'No warnings. Hooray!'
    end
  end
end
