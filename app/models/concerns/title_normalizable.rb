# frozen_string_literal: true

# Adds a `normalized_title` mirror of `title`: lowercased, diacritic-stripped,
# and reduced to alphanumerics only. Used by the import dedupe path so spacing,
# case, and punctuation variants of the same title (e.g., "Zo Maar" vs
# "Zomaar", "Don't" vs "Dont") collapse to the same key.
module TitleNormalizable
  extend ActiveSupport::Concern

  included do
    before_save :set_normalized_title, if: :will_save_change_to_title?
  end

  def self.normalize(raw_title)
    return nil if raw_title.blank?

    raw_title.unicode_normalize(:nfkd).gsub(/\p{Mn}/, '')
      .downcase.gsub(/[^a-z0-9]/, '')
      .presence
  end

  private

  def set_normalized_title
    self.normalized_title = normalize_title
  end

  def normalize_title
    TitleNormalizable.normalize(title)
  end
end
