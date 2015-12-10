module Restforce
  module Bulk
    class Result
      include Restforce::Bulk::Attributes

      attr_accessor :id, :success, :created, :error, :job_id, :batch_id

      def initialize(attributes={})
        assign_attributes(attributes)
      end
    end
  end
end
