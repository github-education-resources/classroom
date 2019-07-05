# frozen_string_literal: true

module Orgs
  class LtiConfigurationsController < Orgs::Controller
    before_action :ensure_lti_launch_flipper_is_enabled

    def link_lms_classroom; end

    def lms_configuration; end
  end
end
