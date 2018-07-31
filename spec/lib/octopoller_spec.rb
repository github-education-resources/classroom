# frozen_string_literal: true

require "rails_helper"

RSpec.describe Octopoller do
  describe "poll with timeout" do
    it "does not accept negative wait time" do
      expect { Octopoller.poll(wait: -(1.second), timeout: 1.second) {} }
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
      result = Octopoller.poll(timeout: 1.second) { "Success!" }
      expect(result).to eq("Success!")
    end

    it "polls until successful return" do
      polled = false
      result = Octopoller.poll(wait: 0.01.seconds, timeout: 1.second) do
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
        Octopoller.poll(wait: 0.01.seconds, timeout: 0.01) do
          raise StandardError, "An error occuered"
        end
      end.to raise_error(StandardError, "An error occuered")
    end
  end

  describe "poll with retries" do
    it "does not accept negative wait time" do
      expect { Octopoller.poll(wait: -(1.second), retries: 1) {} }
        .to raise_error(ArgumentError, "Cannot wait backwards in time")
    end

    it "does not accept negative retries" do
      expect { Octopoller.poll(retries: -1) {} }
        .to raise_error(ArgumentError, "Cannot retry something a negative number of times")
    end

    it "accepts 0 retries" do
      expect { Octopoller.poll(wait: 0.01.seconds, retries: 0) { } }.to_not raise_error(ArgumentError)
    end

    it "poll until max retries reached" do
      expect do
        Octopoller.poll(wait: 0.01.seconds, retries: 2) do
          :re_poll
        end
      end.to raise_error(Octopoller::TooManyAttemptsError, "Polled maximum number of attempts")
    end

    it "tries exactly the number of retries" do
      attempts = 0
      expect do
        Octopoller.poll(wait: 0.01.seconds, retries: 3) do
          attempts += 1
          :re_poll
        end
      end.to raise_error(Octopoller::TooManyAttemptsError, "Polled maximum number of attempts")
      expect(attempts).to eq(4)
    end

    describe "tries with expoential back off" do
      before(:all) do
        start = Time.now.utc
        @times = []
        Octopoller.poll(wait: :exponentially, retries: 3) do
          @times << Time.now.utc
          :re_poll if @times.count < 3
        end
        @times = @times.map { |time| time - start }
      end

      it "retries double in wait time" do
        expect(@times[1]).to be > @times[0] * 2
        expect(@times[2]).to be > @times[1] * 2
      end
    end

    it "exits on successful return" do
      result = Octopoller.poll(retries: 1) { "Success!" }
      expect(result).to eq("Success!")
    end

    it "try until successful return" do
      tried = false
      result = Octopoller.poll(wait: 0.01.seconds, retries: 1) do
        if tried
          "Success!"
        else
          tried = true
          :re_poll
        end
      end
      expect(result).to eq("Success!")
    end

    it "doesn't swallow a raised error" do
      expect do
        Octopoller.poll(wait: 0.01.seconds, retries: 0) do
          raise StandardError, "An error occuered"
        end
      end.to raise_error(StandardError, "An error occuered")
    end
  end
end
