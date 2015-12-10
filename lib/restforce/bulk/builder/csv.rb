module Restforce
  module Bulk
    module Builder
      class Csv
        attr_accessor :operation

        def initialize(operation)
          self.operation = operation
        end

        def transform(data, operation)
          operation == 'query' ? query(data) : generate(data)
        end

        def query(data)
          data
        end

        def generate(data)
          ::CSV.generate do |csv|
            csv << data.first.keys

            data.each do |attributes|
              csv << attributes.values
            end
          end
        end
      end
    end
  end
end
