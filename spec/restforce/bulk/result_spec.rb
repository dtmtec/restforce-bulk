require "spec_helper"

describe Restforce::Bulk::Result, mock_restforce: true do
  let(:raw_response_body) { '' }

  let(:response_body) do
    Restforce::Mash.new(::MultiXml.parse(raw_response_body))
  end

  let(:restforce_response) { build_restforce_response(200, response_body) }

  describe "#content" do
    subject(:result) { described_class.new(id: id, job_id: job_id, batch_id: batch_id) }

    let(:job_id)   { SecureRandom.hex(18) }
    let(:batch_id) { SecureRandom.hex(18) }
    let(:id)       { SecureRandom.hex(18) }

    let(:results) do
      [
        { id: SecureRandom.hex(18), name: 'Some Name 1', description: 'Some Description 1' },
        { id: SecureRandom.hex(18), name: 'Some Name 2', description: 'Some Description 2' },
        { id: SecureRandom.hex(18), name: 'Some Name 3', description: 'Some Description 3' },
        { id: SecureRandom.hex(18), name: 'Some Name 4', description: 'Some Description 4' },
      ]
    end

    let(:raw_response_body) do
      build_bulk_xml(:queryResult, 'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance") do |xml|
        results.each do |result|
          xml.records('xsi:type' => 'sObject') do
            result.each do |key, value|
              xml.send(key.to_s.camelize, value)
            end

            xml.type 'Account'
          end
        end
      end
    end

    it "retrieves result content from salesforce using the given job_id, batch_id and id" do
      expect_restforce_request(:get, "job/#{job_id}/batch/#{batch_id}/result/#{id}").and_return(restforce_response)

      result.content
    end

    it "returns the query result" do
      allow_restforce_request(:get, "job/#{job_id}/batch/#{batch_id}/result/#{id}").and_return(restforce_response)

      expect(result.content).to eq(response_body.queryResult)
    end

    context "when the content type is CSV" do
      let(:response_body) do
        CSV.parse(raw_response_body, headers: true)
      end

      let(:raw_response_body) do
        CSV.generate do |csv|
          csv << results.first.keys.map(&:to_s).map(&:camelize)

          results.each do |result|
            csv << result.values
          end
        end
      end

      it "returns the parsed CSV" do
        allow_restforce_request(:get, "job/#{job_id}/batch/#{batch_id}/result/#{id}").and_return(restforce_response)

        expect(result.content).to eq(CSV.parse(raw_response_body, headers: true))
      end
    end
  end
end
