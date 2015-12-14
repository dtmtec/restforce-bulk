module Restforce
  module Bulk
    module Builder
      class ZipXml < Xml
        def transform(data, operation, content_type)
          zipper = Restforce::Bulk::Zipper.new(data, content_type)
          File.read(zipper.zip)
        end

        def create_request_txt(data)
          build_xml(:sObjects, "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance") do |xml|
            data.each do |item|
              xml.sObject do
                xml.Name item[:filename]
                xml.ParentId item[:parent_id]
                xml.Body "##{item[:filename]}"
              end
            end
          end
        end
      end
    end
  end
end
