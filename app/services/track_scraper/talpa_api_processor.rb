# frozen_string_literal: true

class TrackScraper::TalpaApiProcessor < TrackScraper
  # Data example
  # { 'data' =>
  #     { 'station' =>
  #         { 'getPlayouts' =>
  #             { 'playouts' => [
  #               { 'track' =>
  #                  { 'id' => '8804024d-7542-5176-8d44-f943e8a31bb6',
  #                    'title' => 'All Alone On Christmas',
  #                    'artistName' => 'Darlene Love',
  #                    'isrc' => 'USAV70500298',
  #                    'images' =>
  #                      [{ 'uri' => 'https://img.talparad.io/tracks/USAV70500298.jpg',
  #                         'imageType' => 'image',
  #                         'title' => 'Darlene Love - All Alone on Christmas' }] },
  #                'rankings' => [] },
  #               { 'track' => { 'id' => 'cabb9acf-33e3-5f1c-a412-73fb88d97a4e',
  #                             'title' => 'Feliz Navidad',
  #                             'artistName' => 'Jose Feliciano',
  #                             'isrc' => 'USRC19900930',
  #                             'images' => [{ 'uri' => 'https://img.talparad.io/tracks/USRC19900930.jpg',
  #                                            'imageType' => 'image',
  #                                            'title' => 'José Feliciano - Feliz Navidad' }] },
  #                'rankings' => [] },
  #               { 'track' =>
  #                  { 'id' => '1da36648-a3c0-5825-b75a-02ddb7b11b82',
  #                    'title' => 'Put A Little Love In Your Heart',
  #                    'artistName' => 'Annie Lennox & Al Green',
  #                    'isrc' => 'USAM18800030',
  #                    'images' => [] },
  #                'rankings' => [] }
  #             }
  #         }
  #     }
  # }
  def last_played_song
    api_header = { 'x-api-key': ENV['TALPA_API_KEY'] }
    response = make_request(api_header)
    raise StandardError if response.blank?
    raise StandardError, response[:errors] if response[:errors].present?

    track = response.dig(:data, :station, :getPlayouts, :playouts, 0, :track)
    return false if track.blank?

    @artist_name = track[:artistName].titleize
    @title = TitleSanitizer.sanitize(track[:title]).titleize
    @isrc_code = track[:isrc]
    true
  rescue StandardError => e
    Rails.logger.info(e.message)
    ExceptionNotifier.notify_new_relic(e)
    false
  end
end
