# frozen_string_literal: true

require "ruby-progressbar"

class OrganizationWebhookHealthService
  class Result
    def self.success
      new(:success)
    end

    def self.failed(error)
      new(:failed, error: error)
    end

    attr_reader :error

    def initialize(status, error: nil)
      @status = status
      @error  = error
    end

    def success?
      @status == :success
    end

    def failed?
      @status == :failed
    end
  end

  def initialize(all_organizations: false)
    @all_organizations = all_organizations
  end

  # Public: Iterates through OrganizationWebhook records and ensures
  # that each record has an active and working webhook.
  #
  # all_organizations - Flag that specifies whether to iterate all OrganizationWebhooks,
  #                     or just the ones with a blank github_id.
  #
  # Returns a result hash with the schema:
  #  {
  #    success: #{array of ensured IDs},
  #    failed: {
  #      "#{error_class_name}": #{array of failed IDs}
  #    }
  #  }
  def self.perform(all_organizations: false)
    new(all_organizations: all_organizations).perform
  end

  # Public: Iterates through OrganizationWebhook records and ensures
  # that each record has an active and working webhook. This method also
  # logs the results in a human readable way.
  #
  # all_organizations - Flag that specifies whether to iterate all OrganizationWebhooks,
  #                     or just the ones with a blank github_id.
  #
  # Returns a result hash with the schema:
  #  {
  #    success: #{array of ensured IDs},
  #    failed: {
  #      "#{error_class_name}": #{array of failed IDs}
  #    }
  #  }
  def self.perform_and_print(all_organizations: false)
    results = perform(all_organizations: all_organizations)
    print_results(results)
    results
  end

  # Public: Iterates through OrganizationWebhook records and ensures
  # that each record has an active and working webhook.
  #
  # Returns a result hash with the schema:
  #  {
  #    success: #{array of ensured IDs},
  #    failed: {
  #      "#{error_class_name}": #{array of failed IDs}
  #    }
  #  }
  #
  # rubocop:disable MethodLength
  # rubocop:disable AbcSize
  def perform
    org_webhook_count = (@all_organizations ? OrganizationWebhook : OrganizationWebhook.where(github_id: nil)).count

    progress_bar = ProgressBar.create(
      title: "Iterating over OrganizationWebhooks",
      starting_at: 0,
      total: org_webhook_count,
      format: "%t: %a %e %c/%C (%j%%) %R |%B|",
      throttle_rate: 0.5,
      output: Rails.env.test? ? StringIO.new : STDERR
    )

    success_org_webhooks = []
    failed_org_webhooks = {}
    (@all_organizations ? OrganizationWebhook : OrganizationWebhook.where(github_id: nil))
      .find_in_batches(batch_size: 100) do |organization_webhooks|
        organization_webhooks.each do |organization_webhook|
          result = ensure_organization_webhook_exists!(organization_webhook)
          if result.success?
            success_org_webhooks << organization_webhook.id
          else
            failed_org_webhooks[result.error.class.to_s] ||= []
            failed_org_webhooks[result.error.class.to_s] << organization_webhook.id
          end
          progress_bar.increment
        end
      end

    {
      success: success_org_webhooks,
      failed: failed_org_webhooks
    }
  end
  # rubocop:enable MethodLength
  # rubocop:enable AbcSize

  private

  # Internal: Creates a OrganizationWebhook if one does not exist yet,
  # then creates an GitHubOrgHook if one does not exist, or activates the GitHubOrgHook if it is inactive.
  #
  # organization_webhook - an OrganizationWebhook to call #ensure_webhook_is_active! on.
  #
  # Returns a Result
  def ensure_organization_webhook_exists!(organization_webhook)
    organization_webhook.ensure_webhook_is_active!
    Result.success
  rescue ActiveRecord::RecordInvalid, GitHub::Error, OrganizationWebhook::NoValidTokenError => error
    Result.failed(error)
  end

  # Internal: Prints results from #perform in a human readable way.
  #
  # results - the result hash from #perform with the schema:
  #           {
  #             success: #{array of ensured IDs},
  #             failed: {
  #               "#{error_class_name}": #{array of failed IDs}
  #             }
  #           }
  #
  #
  # Returns nothing.
  private_class_method def self.print_results(results)
    result_string = <<~HEREDOC

      Organization Webhook Health Service Results
      –––––––––––––––––––––––––––––––––––––––––––
      Success count: #{results[:success].count}
      Errored organization webhooks:
      #{results[:failed].to_json}

    HEREDOC
    puts result_string # rubocop:disable Output
  end
end
