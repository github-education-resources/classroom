# frozen_string_literal: true

require "rails_helper"

RSpec.describe Octopoller do
  describe "poll" do
    it "does not accept negative wait time" do
      expect { Octopoller.poll(wait: -(1.second)) {} }
        .to raise_error(ArgumentError, "Cannot wait backwards in time")
    end

    it "does not accept negative timeout" do
      expect { Octopoller.poll(timeout: -(1.second)) {} }
        .to raise_error(ArgumentError, "Timed out without even being able to try")
    end

    it "polls until timeout" do
      expect do
        Octopoller.poll(wait: 0.01.seconds, timeout: 0.05.seconds) do
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
      result = Octopoller.poll(wait: 0.01.seconds) do
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
        Octopoller.poll(wait: 0.01.seconds) do
          raise StandardError, "An error occuered"
        end
      end.to raise_error(StandardError, "An error occuered")
    end
  end

  describe "try" do
    it "does not accept negative wait time" do
      expect { Octopoller.try(wait: -(1.second)) {} }
        .to raise_error(ArgumentError, "Cannot wait backwards in time")
    end

    it "does not accept negative attempts" do
      expect { Octopoller.try(attempts: -1) {} }
        .to raise_error(ArgumentError, "Cannot try something a negative number of attempts")
    end

    it "does not accept negative attempts" do
      expect { Octopoller.try(attempts: 0) {} }
        .to raise_error(ArgumentError, "Cannot try something zero attempts")
    end

    it "try until max attempts reached" do
      expect do
        Octopoller.try(wait: 0.01.seconds, attempts: 2) do
          :retry
        end
      end.to raise_error(Octopoller::TooManyAttemptsError, "Tried maximum number of attempts")
    end

    it "tries exactly the number of attempts" do
      attempts = 0
      expect do
        Octopoller.try(wait: 0.01.seconds, attempts: 4) do
          attempts += 1
          :retry
        end
      end.to raise_error(Octopoller::TooManyAttemptsError, "Tried maximum number of attempts")
      expect(attempts).to eq(4)
    end

    describe "tries with expoential back off" do
      before(:all) do
        start = Time.now.utc
        @times = []
        Octopoller.try(wait: :exponentially, attempts: 3) do
          @times << Time.now.utc
          :retry if @times.count < 3
        end
        @times = @times.map { |time| time - start }
      end

      it "attempts double in wait time" do
        expect(@times[1]).to be > @times[0] * 2
        expect(@times[2]).to be > @times[1] * 2
      end
    end

    it "exits on successful return" do
      result = Octopoller.try { "Success!" }
      expect(result).to eq("Success!")
    end

    it "try until successful return" do
      tried = false
      result = Octopoller.try(wait: 0.01.seconds) do
        if tried
          "Success!"
        else
          tried = true
          :retry
        end
      end
      expect(result).to eq("Success!")
    end

    it "doesn't swallow a raised error" do
      expect do
        Octopoller.try(wait: 0.01.seconds) do
          raise StandardError, "An error occuered"
        end
      end.to raise_error(StandardError, "An error occuered")
    end
  end
end
