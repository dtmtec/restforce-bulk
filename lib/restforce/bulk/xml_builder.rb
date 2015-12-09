module Restforce
  module Bulk
    module XmlBuilder
      def build_xml(root, &block)
        Nokogiri::XML::Builder.new { |xml|
          xml.send(root, xmlns: 'http://www.force.com/2009/06/asyncapi/dataload', &block)
        }.to_xml
      end
    end
  end
end
