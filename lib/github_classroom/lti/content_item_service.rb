# frozen_string_literal: true

module GitHubClassroom
  module LTI
    class ContentItemService
      include Mixins::RequestSigning

      def initialize(content_item_return_url, consumer_key, shared_secret)
        @content_item_return_url = content_item_return_url
        @consumer_key = consumer_key
        @secret = shared_secret
      end

      def build_lti_link(title, launch_url, opts = {}, custom_attributes: {})
        link_item = IMS::LTI::Models::ContentItems::LtiLinkItem.new(
          title: title,
          url: launch_url,
          media_type: "application/vnd.ims.lti.v1.ltilink",
          custom: custom_attributes
        )

        opts.each_pair do |k,v|
          link_item.send("#{k}=", v) if link_item.respond_to?("#{k}=")
        end

        link_item
      end

      # ??? for some reason it's all done via.... dynamically generated forms?
      # def submit_content(content_item, data: "")
      #  request_body = build_request_body([content_item], data: data).to_json
      #  request = signed_request(@content_item_return_url, @consumer_key, @secret, body: request_body)
      #  response = request.post
      #end

      def signed_content(content_item, data: "")
        build_request_body([content_item], data: data)
      end

      # private

      def build_content_item_container(content_items)
        IMS::LTI::Models::ContentItemContainer.new(
          graph: content_items
        )
      end

      def build_request_body(content_items, data: "")
        {
          content_items: build_content_item_container(content_items).to_json,
          data: data,
          lti_message_type: "ContentItemSelection",
          lti_version: "LTI-1p0"
        }
      end
    end
  end
end
