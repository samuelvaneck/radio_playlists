# frozen_string_literal: true

class TitleSanitizer
  # Matches patterns like "#89: ", "#1: ", "#89 ", "89: ", "89. ", "#10000: "
  CHART_POSITION_REGEX = /\A\#?\d{1,5}[:.]\s*/

  def self.sanitize(title)
    new(title).sanitize
  end

  def initialize(title)
    @title = title.to_s
  end

  def sanitize
    result = @title.dup
    result = remove_chart_position(result)
    result.strip
  end

  private

  def remove_chart_position(text)
    text.sub(CHART_POSITION_REGEX, '')
  end
end
