module Restforce
  module Bulk
    module Builder
      class Xml
        attr_accessor :operation

        def initialize(operation)
          self.operation = operation
        end

        def job(object_name, content_type, external_id_field=nil)
          build_xml(:jobInfo) do |xml|
            xml.operation operation
            xml.object object_name
            xml.externalIdFieldName external_id_field if external_id_field
            xml.contentType content_type
          end
        end

        def close
          build_xml(:jobInfo) do |xml|
            xml.state 'Closed'
          end
        end

        def abort
          build_xml(:jobInfo) do |xml|
            xml.state 'Aborted'
          end
        end

        def transform(data, operation, content_type)
          operation == 'query' ? query(data) : generate(data)
        end

        def query(data)
          data
        end

        def generate(data)
          build_xml(:sObjects) do |xml|
            data.each do |item|
              xml.sObject do
                item.each do |attr, value|
                  xml.send(attr, value)
                end
              end
            end
          end
        end

        protected

        def build_xml(root, options={}, &block)
          Nokogiri::XML::Builder.new { |xml|
            xml.send(root, { xmlns: 'http://www.force.com/2009/06/asyncapi/dataload' }.merge(options), &block)
          }.to_xml(encoding: 'UTF-8')
        end
      end
    end
  end
end
