require "spec_helper"

describe Restforce::Bulk::Zipper do
  let(:files_mapping) { [{ full_filename: file_fixture('attachments/image.jpg'), filename: 'image.jpg', parent_id: 'ABC123' }, { full_filename: file_fixture('attachments/subfolder/image.jpg'), filename: 'subfolder/image.jpg', parent_id: 'DEF987' }] }
  subject(:zipper)    { described_class.new(files_mapping) }

  it "generates a zip file, using the given name" do
    output_filename = zipper.zip

    expect(File.exist?(output_filename)).to be_truthy
  end

  it "properly creates a zip with a request.txt file in the root of the zip" do
    output_filename = zipper.zip

    Zip::File.open(output_filename) do |zip_file|
      expect(zip_file.glob('request.txt')).to_not be_empty
    end
  end

  it "adds all files to the zip as well, with their content" do
    output_filename = zipper.zip

    Zip::File.open(output_filename) do |zip_file|
      files_mapping.each do |mapping|
        expect(zip_file.glob(mapping[:filename])).to_not be_empty
        expect(zip_file.glob(mapping[:filename]).first.get_input_stream.read).to eq(File.read(mapping[:full_filename]))
      end
    end
  end

  context "when using default content type of zip/xml" do
    it "creates the zip with proper XML data for request.txt file in the root of the zip" do
      output_filename = zipper.zip

      Zip::File.open(output_filename) do |zip_file|
        content = zip_file.glob('request.txt').first.get_input_stream.read
        expect(content).to eq(File.read(file_fixture('request-xml.txt')))
      end
    end
  end

  context "when using zip/csv content type" do
    subject(:zipper) { described_class.new(files_mapping, :zip_csv) }

    it "creates the zip with proper CSV data for request.txt file in the root of the zip" do
      output_filename = zipper.zip

      Zip::File.open(output_filename) do |zip_file|
        content = zip_file.glob('request.txt').first.get_input_stream.read
        expect(content).to eq(File.read(file_fixture('request-csv.txt')))
      end
    end
  end
end
