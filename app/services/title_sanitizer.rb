# frozen_string_literal: true

class TitleSanitizer
  # Matches patterns like "#89: ", "#1: ", "#89 ", "89: ", "89. ", "#10000: "
  CHART_POSITION_REGEX = /\A\#?\d{1,5}[:.]\s*/

  # Matches FunX program prefixes like "**FF FunX New Week 49 ", "*D FunX DiXte Week 50 "
  # Also handles titleized variants like "**Ff Fun X New Week 04 ", "*D Fun X Di Xte Week 50 "
  FUNX_PROGRAM_PREFIX_REGEX = /\A\*+\w+\s+Fun\s*X\s+(?:\w+\s+)*Week\s+\d+\s+/i

  def self.sanitize(title)
    new(title).sanitize
  end

  def initialize(title)
    @title = title.to_s
  end

  def sanitize
    result = @title.dup
    result = remove_chart_position(result)
    result = remove_funx_program_prefix(result)
    result.strip
  end

  private

  def remove_chart_position(text)
    text.sub(CHART_POSITION_REGEX, '')
  end

  def remove_funx_program_prefix(text)
    text.sub(FUNX_PROGRAM_PREFIX_REGEX, '')
  end
end
