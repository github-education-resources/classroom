# frozen_string_literal: true

# Use ActiveJob config for async index updates.
Chewy.strategy(:active_job)

# Chewy wraps controller actions in the atomic strategy by default.
# We change this to use ActiveJob here. Makes index updates async, outside
# of the request.
Chewy.request_strategy = :active_job
