module Stafftools
  class RepoAccessesController < StafftoolsController
    before_action :set_repo_access

    def show
    end

    def edit
    end

    def update
    end

    def destroy
    end

    private

    def set_repo_access
      @repo_access = RepoAccess.find_by(id: params[:id])
    end
  end
end
