# frozen_string_literal: true

class PagesController < ApplicationController
  include I18nHelper

  layout "layouts/pages"

  skip_before_action :authenticate_user!

  def home
    redirect_to organizations_path if logged_in?

    ticker_stat = TickerStat.order("created_at").last

    @teacher_count = ticker_stat.user_count
    @repo_count = ticker_stat.repo_count

    ## TODO: Remove before merge
    ## Just for testing formatting with real numbers
    @teacher_count = 190_80
    @repo_count = 284_483_08
  end

  def desktop; end
end
