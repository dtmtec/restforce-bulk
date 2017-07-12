module Restforce
  module Bulk
    class Job
      include Restforce::Bulk::Attributes

      JOB_CONTENT_TYPE_MAPPING = {
        csv: 'CSV',
        xml: 'XML',
        zip_csv: 'ZIP_CSV',
        zip_xml: 'ZIP_XML'
      }

      class << self
        def create(operation, object_name, content_type=:xml, external_id_field=nil)
          builder  = Restforce::Bulk::Builder::Xml.new(operation)
          data     = builder.job(object_name, JOB_CONTENT_TYPE_MAPPING[content_type.to_sym], external_id_field)

          response = Restforce::Bulk.client.perform_request(:post, 'job', data)

          new(response.body.jobInfo)
        end

        def find(id)
          response = Restforce::Bulk.client.perform_request(:get, "job/#{id}")

          new(response.body.jobInfo)
        end
      end

      attr_accessor :id, :operation, :object, :created_by_id, :created_date,
                    :system_modstamp, :state, :content_type

      def initialize(attributes={})
        assign_attributes(attributes)

        @batches = []
      end

      def content_type=(value)
        @content_type = JOB_CONTENT_TYPE_MAPPING.invert[value] || value
      end

      def batches
        @batches
      end

      def reload_batches
        response = Restforce::Bulk.client.perform_request(:get, "job/#{id}/batch")
        parser   = Restforce::Bulk::Parser::Xml.new

        @batches = parser.batches(response.body).map do |batch_info|
          Restforce::Bulk::Batch.new(batch_info)
        end
      end

      def add_batch(data)
        Restforce::Bulk::Batch.create(id, data, operation, content_type).tap do |batch|
          batches << batch
        end
      end

      def close
        builder = Restforce::Bulk::Builder::Xml.new(operation)

        response = Restforce::Bulk.client.perform_request(:post, "job/#{id}", builder.close)

        assign_attributes(response.body.jobInfo)
      end

      def abort
        builder = Restforce::Bulk::Builder::Xml.new(operation)

        response = Restforce::Bulk.client.perform_request(:post, "job/#{id}", builder.abort)

        assign_attributes(response.body.jobInfo)
      end
    end
  end
end
