module Restforce
  module Bulk
    class Batch
      include Restforce::Bulk::XmlBuilder
      extend Restforce::Bulk::XmlBuilder

      class << self
        def create(job_id, data, operation, content_type=:xml)
          response = Restforce::Bulk.client.perform_request(:post, "job/#{job_id}/batch", data)

          new(response.body.batchInfo)
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
