module Restforce
  module Bulk
    class Batch
      include Restforce::Bulk::Attributes

      class << self
        def create(job_id, data, operation, content_type=:xml)
          builder  = builder_class_for(content_type).new(operation)

          response = Restforce::Bulk.client.perform_request(:post, "job/#{job_id}/batch", builder.transform(data, operation), content_type)

          new(response.body.batchInfo)
        end

        def find(job_id, id)
          response = Restforce::Bulk.client.perform_request(:get, "job/#{job_id}/batch/#{id}")

          new(response.body.batchInfo)
        end

        def builder_class_for(content_type)
          Restforce::Bulk::Builder.const_get(content_type.to_s.camelize)
        end
      end

      attr_accessor :id, :job_id, :state, :created_date, :system_modstamp, :number_records_processed

      def initialize(attributes={})
        assign_attributes(attributes)
      end

      def queued?
        state == 'Queued'
      end

      def in_progress?
        state == 'InProgress'
      end

      def completed?
        state == 'Completed'
      end

      def failed?
        state == 'Failed'
      end

      def not_processed?
        state == 'Not Processed'
      end
    end
  end
end
