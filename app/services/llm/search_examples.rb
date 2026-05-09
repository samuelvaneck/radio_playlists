# frozen_string_literal: true

# Static catalogue of example natural language queries the frontend can render as
# clickable suggestions next to the search bar. Bilingual (EN/NL) so the UI can
# pick the right label for the active locale, and tagged by `category` so the
# frontend can group them or sample one per category.
#
# These doubles as ad-hoc documentation of which phrasings the LLM is expected
# to handle: any query here that doesn't translate cleanly via
# `Llm::QueryTranslator` is a prompt regression worth investigating.
module Llm
  module SearchExamples
    EXAMPLES = [
      { en: 'songs about freedom', nl: 'nummers over vrijheid', category: 'theme' },
      { en: 'love songs from the 90s', nl: 'liefdesnummers uit de jaren 90', category: 'theme' },
      { en: 'songs about heartbreak by Adele', nl: 'liefdesverdriet nummers van Adele', category: 'theme' },
      { en: 'party songs about dancing', nl: 'feestnummers over dansen', category: 'theme' },
      { en: 'songs about drugs and addiction', nl: 'nummers over drugs en verslaving', category: 'theme' },
      { en: 'songs about hope and the future', nl: 'nummers over hoop en de toekomst', category: 'theme' },
      { en: 'upbeat Dutch songs played on Radio 538 last week', nl: 'vrolijke Nederlandse nummers op Radio 538 van afgelopen week',
        category: 'mood' },
      { en: 'sad acoustic songs', nl: 'droevige akoestische nummers', category: 'mood' },
      { en: 'top 3 most played songs this month', nl: 'top 3 meest gedraaide nummers deze maand', category: 'chart' },
      { en: 'British rock songs from the 80s', nl: 'Britse rocknummers uit de jaren 80', category: 'genre' }
    ].freeze

    def self.list
      EXAMPLES.map(&:dup)
    end
  end
end
