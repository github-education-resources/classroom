# frozen_string_literal: true

module Stafftools
  class ResourcesController < StafftoolsController
    before_action :set_resources

    def index; end

    def search
      respond_to do |format|
        format.html { render partial: "stafftools/resources/search_results", locals: { resources: @resources } }
      end
    end

    private

    def set_resources
      return if params[:query].blank?
      @resources = StafftoolsMultiTableSearch.search(params[:query])
    end
  end
end
