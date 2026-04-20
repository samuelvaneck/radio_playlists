# frozen_string_literal: true

module Sluggable
  extend ActiveSupport::Concern

  TRANSLITERATION_LOCALES = %i[russian greek].freeze

  def update_slug
    update!(slug: next_slug)
  end

  private

  def set_slug
    return if slug.present?

    self.slug = next_slug
  end

  def next_slug
    unique_slug(slug_base)
  end

  def slug_base
    base = slug_source.to_s.to_slug.transliterate(*TRANSLITERATION_LOCALES).normalize.to_s
    base.presence || "#{self.class.model_name.singular}-#{SecureRandom.hex(4)}"
  end

  def unique_slug(base_slug)
    candidate = base_slug
    counter = 1
    while self.class.where(slug: candidate).where.not(id:).exists?
      counter += 1
      candidate = "#{base_slug}-#{counter}"
    end
    candidate
  end
end
