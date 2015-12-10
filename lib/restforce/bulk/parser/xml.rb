module Restforce
  module Bulk
    module Parser
      class Xml
        def batches(data)
          parsed_data = Restforce::Mash.new(::MultiXml.parse(data))

          wrap_in_array(parsed_data.batchInfoList.batchInfo)
        end

        def results_on(data)
          if data.results
            wrap_in_array(data.results.result)
          else
            [{ id: data.result_list.result }]
          end
        end

        def content_on(data)
          data.queryResult
        end

        protected

        def wrap_in_array(value)
          value.is_a?(Array) ? value : [value]
        end
      end
    end
  end
end
