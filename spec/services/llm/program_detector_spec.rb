# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Llm::ProgramDetector, type: :service do
  let(:service) do
    described_class.new(artist_name: artist_name, title: title, radio_station_name: radio_station_name)
  end

  describe '#program?' do
    subject(:program?) { service.program? }

    context 'when the LLM identifies a radio program' do
      let(:artist_name) { 'SLAM!' }
      let(:title) { 'Housuh In De Pauzuh' }
      let(:radio_station_name) { 'SLAM!' }

      before do
        allow(service).to receive(:chat).and_return('yes')
      end

      it 'returns true' do
        expect(program?).to be true
      end

      it 'stores the raw response', :aggregate_failures do
        program?
        expect(service.raw_response[:request]).to include('SLAM!')
        expect(service.raw_response[:response]).to eq('yes')
      end
    end

    context 'when the LLM identifies an actual song' do
      let(:artist_name) { 'Tiësto' }
      let(:title) { 'Red Lights' }
      let(:radio_station_name) { 'SLAM!' }

      before do
        allow(service).to receive(:chat).and_return('no')
      end

      it 'returns false' do
        expect(program?).to be false
      end
    end

    context 'when the LLM returns nil' do
      let(:artist_name) { 'SLAM!' }
      let(:title) { 'Housuh In De Pauzuh' }
      let(:radio_station_name) { 'SLAM!' }

      before do
        allow(service).to receive(:chat).and_return(nil)
      end

      it 'returns false' do
        expect(program?).to be false
      end
    end

    context 'when the LLM returns yes with extra text' do
      let(:artist_name) { 'Radio 538' }
      let(:title) { 'De Ochtendshow' }
      let(:radio_station_name) { 'Radio 538' }

      before do
        allow(service).to receive(:chat).and_return('Yes, this is a radio program')
      end

      it 'returns true' do
        expect(program?).to be true
      end
    end
  end
end
