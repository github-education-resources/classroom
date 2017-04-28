# frozen_string_literal: true

module Stafftools
  class RepoAccessesController < StafftoolsController
    before_action :set_repo_access

    def show; end

    private

    def set_repo_access
      @repo_access = RepoAccess.find_by!(id: params[:id])
    end
  end
end
