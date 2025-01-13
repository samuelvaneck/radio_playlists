module Youtube
  class Filter
    attr_reader :args, :filtered_videos

    def initialize(args)
      @args = args
      @filtered_videos = args[:videos]
    end

    def only_official
      @filtered_videos = @filtered_videos.select do |video|
        video['snippet']['title'].downcase.include?('official')
      end
    end

    def with_same_title
      @filtered_videos = @filtered_videos.select do |video|
        video['snippet']['title'].downcase.include?(args[:title].downcase)
      end
    end
  end
end
