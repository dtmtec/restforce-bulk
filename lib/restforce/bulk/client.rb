module Restforce
  module Bulk
    class Client
      def initialize(restforce_client=nil)
        @restforce_client = restforce_client
      end

      def connection
        @connection ||= (@restforce_client || Restforce.new).tap do |client|
          client.authenticate!
          client.middleware.insert_after Restforce::Middleware::Authorization, Restforce::Bulk::Middleware::Authorization, client, client.options
          client.middleware.response :xml, content_type: /\bxml$/
        end
      end

      def perform_request(method, path, data=nil, content_type=:xml, headers={})
        result_headers = content_type_header_for(content_type).merge(headers)

        connection.send(method, [base_path, path].join('/'), data, result_headers)
      end

      private

      def base_path
        @base_path ||= "/services/async/#{connection.options[:api_version]}"
      end

      def content_type_header_for(content_type)
        { 'Content-Type' => "#{mime_type_for(content_type)} ;charset=UTF-8" }
      end

      def mime_type_for(content_type)
        Restforce::Bulk::MIME_TYPE_MAPPING[(content_type || :csv).to_sym]
      end
    end
  end
end
