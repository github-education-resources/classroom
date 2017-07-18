# frozen_string_literal: true

unless Rails.env.test?
  Peek.into Peek::Views::Git, nwo: "education/classroom"
  Peek.into Peek::Views::PerformanceBar
  Peek.into Peek::Views::GC

  # Only show the Dalli view if we are actually caching.
  if Rails.env.production? || Rails.root.join("tmp", "caching-dev.txt").exist?
    Peek.into Peek::Views::Dalli
  end

  Peek.into Peek::Views::PG
  Peek.into Peek::Views::Sidekiq
end
