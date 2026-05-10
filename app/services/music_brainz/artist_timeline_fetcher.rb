# frozen_string_literal: true

module MusicBrainz
  class ArtistTimelineFetcher
    LOOKUP_ENDPOINT = 'https://musicbrainz.org/ws/2/artist'
    USER_AGENT = 'Airplays/1.0.0 (https://airplays.nl)'
    RATE_LIMIT_DELAY = 1.0
    INCLUDED_RELEASE_GROUP_TYPES = %w[Album EP].freeze

    Result = Struct.new(:events, :wikidata_id, keyword_init: true)

    def initialize(mbid)
      @mbid = mbid
    end

    def call
      return Result.new(events: [], wikidata_id: nil) if @mbid.blank?

      data = fetch_artist
      return Result.new(events: [], wikidata_id: nil) if data.blank?

      Result.new(
        events: build_events(data),
        wikidata_id: extract_wikidata_id(data)
      )
    end

    private

    def fetch_artist
      Rails.cache.fetch(cache_key, expires_in: 24.hours) do
        sleep(RATE_LIMIT_DELAY)
        uri = URI("#{LOOKUP_ENDPOINT}/#{@mbid}")
        uri.query = URI.encode_www_form(inc: 'release-groups artist-rels url-rels', fmt: 'json')

        response = make_request(uri)
        next nil unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      end
    rescue StandardError => e
      Rails.logger.error "MusicBrainz::ArtistTimelineFetcher: #{e.message}"
      nil
    end

    def build_events(data)
      [
        life_span_events(data),
        member_relation_events(data),
        release_group_events(data)
      ].flatten.compact
    end

    def life_span_events(data)
      life_span = data['life-span'] || {}
      type = data['type'].to_s

      events = []
      events << event(category: begin_category(type), date: life_span['begin'], title: begin_title(type, data['name'])) if life_span['begin'].present?
      events << event(category: end_category(type), date: life_span['end'], title: end_title(type, data['name'])) if life_span['end'].present?
      events
    end

    def member_relation_events(data)
      data['relations'].to_a.flat_map do |relation|
        next [] unless relation['type'] == 'member of band'

        target = relation.dig('artist', 'name')
        next [] if target.blank?

        events = []
        events << event(category: 'joined_group', date: relation['begin'], title: "Member of #{target}") if relation['begin'].present?
        events << event(category: 'left_group', date: relation['end'], title: "Left #{target}") if relation['end'].present?
        events
      end
    end

    def release_group_events(data)
      data['release-groups'].to_a.filter_map do |rg|
        next nil unless INCLUDED_RELEASE_GROUP_TYPES.include?(rg['primary-type'])
        next nil if rg['first-release-date'].blank?

        event(
          category: rg['primary-type'].downcase == 'album' ? 'album_released' : 'ep_released',
          date: rg['first-release-date'],
          title: rg['title']
        )
      end
    end

    def extract_wikidata_id(data)
      relation = data['relations'].to_a.find do |rel|
        rel['type'] == 'wikidata' && rel.dig('url', 'resource').to_s.include?('wikidata.org')
      end
      return nil if relation.blank?

      relation.dig('url', 'resource').to_s.split('/').last.presence
    end

    def event(category:, date:, title:)
      { 'category' => category, 'date' => date, 'title' => title, 'source' => 'musicbrainz' }
    end

    def begin_category(type)
      type.casecmp('group').zero? ? 'formation' : 'birth'
    end

    def end_category(type)
      type.casecmp('group').zero? ? 'dissolution' : 'death'
    end

    def begin_title(type, name)
      type.casecmp('group').zero? ? "#{name} formed" : "Birth of #{name}"
    end

    def end_title(type, name)
      type.casecmp('group').zero? ? "#{name} disbanded" : "Death of #{name}"
    end

    def cache_key
      "music_brainz:artist_timeline:#{@mbid}"
    end

    def make_request(uri)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.open_timeout = 10
      https.read_timeout = 10

      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = USER_AGENT
      request['Accept'] = 'application/json'

      https.request(request)
    end
  end
end
