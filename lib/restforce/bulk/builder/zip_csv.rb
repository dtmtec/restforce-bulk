module Restforce
  module Bulk
    module Builder
      class ZipCsv < Csv
        def transform(data, operation, content_type)
          zipper = Restforce::Bulk::Zipper.new(data, content_type)
          File.read(zipper.zip)
        end

        def create_request_txt(data)
          ::CSV.generate do |csv|
            csv << %w{Name ParentId Body}

            data.each do |item|
              csv << [item[:filename], item[:parent_id], "##{item[:filename]}"]
            end
          end
        end
      end
    end
  end
end
