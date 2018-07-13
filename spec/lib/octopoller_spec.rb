# frozen_string_literal: true

require "rails_helper"

RSpec.describe Octopoller do
  it "does not accept negative wait time" do
    expect { Octopoller.poll(wait: -1) {} }.to raise_error(ArgumentError, "Cannot poll backwards in time")
  end

  it "does not accept negative timeout" do
    expect { Octopoller.poll(timeout: -1) {} }.to raise_error(ArgumentError, "Timed out without even being able to try")
  end

  it "polls until timeout" do
    expect do
      Octopoller.poll(wait: 0.1, timeout: 0.5) do
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
    result = Octopoller.poll(wait: 0.1) do
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
      Octopoller.poll(wait: 0.1) do
        raise StandardError, "An error occuered"
      end
    end.to raise_error(StandardError, "An error occuered")
  end


  # describe "polls and captures unique values in order" do
  #   before(:all) do
  #     @errors = []
  #     error_handler = proc { |error| @errors << error }
  #     counter = 0
  #     Octopoller.poll(wait: 0.1, error_handler: error_handler) do
  #       counter += 1
  #       case counter
  #       when 1
  #         re_poll
  #         "Counter is 1"
  #       when 2
  #         re_poll
  #         "Counter is 2"
  #       when 3
  #         re_poll
  #         "Counter is 3"
  #       when 4
  #         counter
  #       end
  #     end
  #   end

  #   it "captured the first error" do
  #     expect { raise @errors[0] }.to raise_error(StandardError, "Counter is 1")
  #   end

  #   it "captured the second error" do
  #     expect { raise @errors[1] }.to raise_error(StandardError, "Counter is 2")
  #   end

  #   it "captured the thrid error" do
  #     expect { raise @errors[2] }.to raise_error(StandardError, "Counter is 3")
  #   end
  # end
end
