# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password]

# Since we're hosted on Heroku for now, also filter out most params from logs
# When we switch to internal infra, maybe we can remove this?
Rails.application.config.filter_parameters << ParameterFiltering.filtered_params_proc
