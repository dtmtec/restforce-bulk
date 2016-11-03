module Restforce
  module Bulk
    module Middleware
      class ParseCsv < ::FaradayMiddleware::ResponseMiddleware
        dependency 'csv'

        define_parser do |body|
          body.force_encoding("utf-8")
          ::CSV.parse(body, headers: true)
        end
      end
    end
  end
end
