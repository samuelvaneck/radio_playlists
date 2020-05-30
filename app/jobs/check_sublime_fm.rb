# frozen_string_literal: true

class CheckSublimeFm < ApplicationJob 
  queue_as :default

  def perform
    Generalplaylist.sublime_fm_check
  end
end
