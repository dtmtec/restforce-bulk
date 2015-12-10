module Restforce
  module Bulk
    module Attributes
      def assign_attributes(value)
        value.each do |attr, value|
          send("#{attr.to_s.underscore}=", value) if respond_to?("#{attr.to_s.underscore}=")
        end
      end
    end
  end
end
