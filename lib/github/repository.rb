module GitHub
  class Repository
    class << self
      def present?(client, full_name)
        client.repository?(full_name)
      end
    end
  end
end
