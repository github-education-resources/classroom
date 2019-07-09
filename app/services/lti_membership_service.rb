class LtiMembershipService
  def initialize(lti_configuration)
    raise "given LtiConfiguration must exist" unless lti_configuration.present?

    @lti_configuration = lti_configuration
  end

  # TODO: this method is probably entirely unnecessary
  def get_membership_from_nonce(nonce)
    message_store = GitHubClassroom.lti_message_store(
      consumer_key: lti_configuration.consumer_key
    )
    launch_message = message_store.get_message(nonce)
    auth_params = launch_message.oauth_params
    custom_params = launch_message.custom_params

    membership_service_url = custom_params[:custom_context_memberships_url]
    return nil unless membership_service_url

    get_membership(membership_service_url)
  end

  def get_membership(endpoint)
    response = make_signed_membership_request(endpoint)

    raise 'error fetching membership' unless response.status == 200
    membership_container = JSON.parse(response.body)

    build_memberships_list(membership_container)
  end

  def build_memberships_list(membership_container)
    memberships_list = []

    memberships = membership_container.dig("pageOf", "membershipSubject", "membership")
    memberships.each do |membership|
      symbolized_membership = membership.deep_transform_keys { |key| key.underscore.to_sym }
      symbolized_member = symbolized_membership[:member]

      parsed_member = IMS::LTI::Models::MembershipService::LISPerson.new(symbolized_member)
      symbolized_membership[:member] = parsed_member

      parsed_membership = IMS::LTI::Models::MembershipService::Membership.new(symbolized_membership)
      memberships_list.push(parsed_membership)
    end

    memberships_list
  end

  def make_signed_membership_request(endpoint)
    secret = @lti_configuration.shared_secret
    consumer_key = @lti_configuration.consumer_key

    consumer = OAuth::Consumer.new(consumer_key, secret, site: endpoint)
    req = Net::HTTP::Get.new(endpoint,nil)
    helper = OAuth::Client::Helper.new(req, consumer: consumer, request_uri: endpoint)
    helper.hash_body

    response = Faraday.get(endpoint) do |r|
      r.headers["Authorization"] = helper.header
      r.headers["Accept"] = "application/vnd.ims.lis.v2.membershipcontainer+json"
    end

    response
  end
end
