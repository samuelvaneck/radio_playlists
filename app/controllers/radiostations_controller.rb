class RadiostationsController < ApplicationController

  def index
    @radiostations = Radiostation.all
  end

end
