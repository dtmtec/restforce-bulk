module Restforce
  module Bulk
    # Piece of middleware that simply injects the OAuth token into the request
    # headers.
    class Middleware::Authorization < Restforce::Middleware
      AUTH_HEADER = 'X-SFDC-Session'.freeze

      def call(env)
        env[:request_headers][AUTH_HEADER] = @options[:oauth_token]
        @app.call(env)
      end
    end
  end
end
