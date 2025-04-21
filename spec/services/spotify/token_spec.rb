# frozen_string_literal: true

require 'rails_helper'

describe Spotify::Token, type: :service do
  let(:spotify_token) { described_class.new }
  let(:auth_str_base64) { Base64.strict_encode64("#{ENV['SPOTIFY_CLIENT_ID']}:#{ENV['SPOTIFY_CLIENT_SECRET']}") }

  describe '#token' do
    subject(:token) { spotify_token.token }

    context 'when the token is cached' do
      before do
        allow(Rails.cache).to receive(:fetch).and_return('cached_token')
      end

      it 'returns the cached token' do
        expect(token).to eq('cached_token')
      end
    end

    context 'when the token is not cached' do
      let(:spotify_token) { described_class.new(cache: false) }

      before do
        allow(Rails.cache).to receive(:fetch).and_call_original
        allow(spotify_token).to receive(:generate_token).and_return('new_token')
      end

      it 'generates a new token' do
        expect(token).to eq('new_token')
      end

      it 'does not call the Rails cache' do
        token
        expect(Rails.cache).not_to have_received(:fetch)
      end
    end

    context 'when an error occurs during token generation' do
      before do
        allow(spotify_token).to receive(:generate_token).and_raise(Spotify::Token::TokenGenerationError)
        allow(ExceptionNotifier).to receive(:notify_new_relic)
      end

      it 'raises a TokenGenerationError' do
        expect { token }.to raise_error(Spotify::Token::TokenGenerationError)
      end
    end
  end
end
