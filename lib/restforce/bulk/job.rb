module Restforce
  module Bulk
    class Job
      include Restforce::Bulk::XmlBuilder
      extend Restforce::Bulk::XmlBuilder

      JOB_CONTENT_TYPE_MAPPING = {
        csv: 'CSV',
        xml: 'XML',
        zip_csv: 'ZIP_CSV',
        zip_xml: 'ZIP_XML'
      }

      class << self
        def create(operation, object_name, content_type=:xml)
          data = build_xml(:jobInfo) do |xml|
            xml.operation operation
            xml.object object_name
            xml.contentType JOB_CONTENT_TYPE_MAPPING[content_type.to_sym]
          end

          response = Restforce::Bulk.client.perform_request(:post, 'job', data)

          new(response.body.jobInfo)
        end
      end

      attr_accessor :id, :operation, :object, :created_by_id, :created_date,
                    :system_modstamp, :state, :content_type

      def initialize(attributes={})
        attributes.each do |attr, value|
          send("#{attr.to_s.underscore}=", value) if respond_to?("#{attr.to_s.underscore}=")
        end

        @batches = []
      end

      def content_type=(value)
        @content_type = JOB_CONTENT_TYPE_MAPPING.invert[value] || value
      end

      def batches
        @batches
      end

      def add_batch(data)
        Restforce::Bulk::Batch.create(id, data, operation, content_type).tap do |batch|
          batches << batch
        end
      end
    end
  end
end
