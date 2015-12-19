module Stafftools
  class NotesController < StafftoolsController
    before_action :find_note, only: [:show]

    def index
      @notes = Note.all
    end

    def show
    end

    private

    def find_note
      @note = Note.find(params[:id])
    end
  end
end
