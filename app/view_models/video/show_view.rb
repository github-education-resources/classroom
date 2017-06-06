# frozen_string_literal: true

module Video
  class ShowView < ViewModel
    attr_reader :id, :title, :provider, :description

    def url
      "https://www.youtube.com/embed/#{id}"
    end
  end
end
