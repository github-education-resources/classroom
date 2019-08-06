# frozen_string_literal: true

require "rails_helper"

class FakeBulkApiJob < BulkApiJob
  def perform(user, some_other_variable, retries: 0); end
end

RSpec.describe BulkApiJob, type: :job do
  include ActiveJob::TestHelper

  subject { FakeBulkApiJob }

  let(:teacher) { classroom_teacher }
  let(:redis) { GitHubClassroom.redis }
  let(:_) { "some other variable" }

  before(:each) do
    redis.keys("user_api_job:*").each { |key| redis.del(key) }
    Timecop.freeze
  end

  after(:each) do
    Timecop.return
  end

  describe "successful execution" do
    context "cooldown does not exist" do
      it "succeeds" do
        expect { subject.perform_later(teacher, _) }.to_not raise_error
      end
    end

    context "cooldown is in the past" do
      before(:each) do
        redis.set("user_api_job:#{teacher.id}", (Time.zone.now - 2.hours).to_datetime)
      end

      it "succeeds" do
        expect { subject.perform_later(teacher, _) }.to_not raise_error
      end
    end
  end

  context "user performing the job is not the first argument" do
    it "raises an exception" do
      expect { subject.perform_later(_, teacher) }.to raise_error(BulkApiJob::Error::MissingUser)
    end
  end

  context "user is already running a bulk API job" do
    before(:each) do
      redis.set("user_api_job:#{teacher.id}", (Time.zone.now + 1.hour).to_datetime)
    end

    # rubocop:disable Rails/TimeZone
    it "perform_later will schedule the job to execute sequentially after the cooldown" do
      expect { subject.perform_later(teacher, _, retries: 1) }
        .to have_enqueued_job(FakeBulkApiJob)
        .at(Time.at((Time.now + 1.hour).to_i))
      expect { subject.perform_later(teacher, _, retries: 1) }
        .to have_enqueued_job(FakeBulkApiJob)
        .at(Time.at((Time.now + 2.hours).to_i))
    end
  end

  context "failure by rate limit or job already running" do
    before(:each) do
      allow_any_instance_of(subject).to receive(:perform).and_raise(GitHub::Forbidden)
    end

    it "does not retry if retries not passed" do
      expect { subject.perform_now(teacher, _) }.to_not have_enqueued_job(FakeBulkApiJob)
    end

    it "does not retry if retries is zero" do
      expect { subject.perform_now(teacher, _, retries: 0) }.to_not have_enqueued_job(FakeBulkApiJob)
    end

    it "does retry if retries are greater than zero" do
      expect { subject.perform_now(teacher, _, retries: 1) }.to have_enqueued_job(FakeBulkApiJob)
    end

    it "decreases retry count and passes correct variables when retrying" do
      expect { subject.perform_now(teacher, _, retries: 2) }
        .to have_enqueued_job(FakeBulkApiJob)
        .with(teacher, _, retries: 1)
    end
  end
end
