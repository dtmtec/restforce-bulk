module Restforce
  module Bulk
    class Zipper
      attr_accessor :files_mapping, :content_type

      def initialize(files_mapping, content_type=:zip_xml)
        self.files_mapping = files_mapping
        self.content_type  = content_type
      end

      def zip
        ::Zip::File.open(output_filename, ::Zip::File::CREATE) do |zip_file|
          zip_file.get_output_stream('request.txt') do |io|
            io.write builder.create_request_txt(files_mapping)
          end

          files_mapping.each do |mapping|
            zip_file.add(mapping[:filename], mapping[:full_filename])
          end
        end

        output_filename
      end

      protected

      def builder
        @builder ||= Restforce::Bulk::Builder.const_get(content_type.to_s.camelize).new('insert')
      end

      def output_filename
        @output_filename ||= "/tmp/#{SecureRandom.hex}.zip"
      end
    end
  end
end
