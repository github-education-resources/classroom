module Stafftools
  class GroupingsController < StafftoolsController
    before_action :set_grouping

    def show
    end

    def edit
    end

    def update
    end

    def destroy
    end

    private

    def set_grouping
      @grouping = Grouping.find_by(id: params[:id])
    end
  end
end
