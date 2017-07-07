module Restforce
  module Bulk
    module Builder
      class Xml
        attr_accessor :operation

        def initialize(operation)
          self.operation = operation
        end

        def job(object_name, content_type)
          build_xml(:jobInfo) do |xml|
            xml.operation operation
            xml.object object_name
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
                  xml.send(attr, value, value.nil? ? {"xsi:nil" => true} : {})
                end
              end
            end
          end
        end

        protected

        def build_xml(root, options={}, &block)
          Nokogiri::XML::Builder.new { |xml|
            namespaces = {
              "xmlns" => 'http://www.force.com/2009/06/asyncapi/dataload',
              "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
            }
            xml.send(root, namespaces.merge(options), &block)
          }.to_xml(encoding: 'UTF-8')
        end
      end
    end
  end
end
