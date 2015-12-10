module Restforce
  module Bulk
    class Batch
      class << self
        def create(job_id, data, operation, content_type=:xml)
          builder  = builder_class_for(content_type).new(operation)

          response = Restforce::Bulk.client.perform_request(:post, "job/#{job_id}/batch", builder.transform(data, operation), content_type)

          new(response.body.batchInfo)
        end

        def builder_class_for(content_type)
          Restforce::Bulk::Builder.const_get(content_type.to_s.camelize)
        end
      end

      attr_accessor :id, :job_id, :state, :created_date, :system_modstamp, :number_records_processed

      def initialize(attributes={})
        attributes.each do |attr, value|
          send("#{attr.to_s.underscore}=", value) if respond_to?("#{attr.to_s.underscore}=")
        end
      end
    end
  end
end
