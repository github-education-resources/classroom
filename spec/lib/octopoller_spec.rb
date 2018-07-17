# frozen_string_literal: true

require "rails_helper"

RSpec.describe Octopoller do
  it "does not accept negative wait time" do
    expect { Octopoller.poll(wait: -1.second) {} }.to raise_error(ArgumentError, "Cannot poll backwards in time")
  end

  it "does not accept negative timeout" do
    expect { Octopoller.poll(timeout: -1.seconds) {} }.to raise_error(ArgumentError, "Timed out without even being able to try")
  end

  it "polls until timeout" do
    expect do
      Octopoller.poll(wait: 0.1.seconds, timeout: 0.5.seconds) do
        :re_poll
      end
    end.to raise_error(Octopoller::TimeoutError, "Polling timed out paitently")
  end

  it "exits on successful return" do
    result = Octopoller.poll { "Success!" }
    expect(result).to eq("Success!")
  end

  it "polls until successful return" do
    polled = false
    result = Octopoller.poll(wait: 0.1.seconds) do
      if polled
        "Success!"
      else
        polled = true
        :re_poll
      end
    end
    expect(result).to eq("Success!")
  end

  it "doesn't swallow a raised error" do
    expect do
      Octopoller.poll(wait: 0.1.seconds) do
        raise StandardError, "An error occuered"
      end
    end.to raise_error(StandardError, "An error occuered")
  end
end
