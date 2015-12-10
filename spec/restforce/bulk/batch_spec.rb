require "spec_helper"

describe Restforce::Bulk::Batch, mock_restforce: true do
  let(:raw_response_body) { '' }

  let(:response_body) do
    Restforce::Mash.new(::MultiXml.parse(raw_response_body))
  end

  let(:restforce_response) { build_restforce_response(200, response_body) }

  describe ".find(job_id, id)" do
    let(:job_id) { SecureRandom.hex(18) }
    let(:id)     { SecureRandom.hex(18) }

    let(:raw_response_body) do
      build_bulk_xml(:batchInfo) do |xml|
        xml.id                     id
        xml.jobId                  job_id
        xml.createdDate            '2009-04-14T18:15:59.000Z'
        xml.systemModstamp         '2009-04-14T18:15:59.000Z'
        xml.state                  'Open'
        xml.numberRecordsProcessed 0
      end
    end

    it "retrieves batch info from salesforce using the given job_id and id" do
      expect_restforce_request(:get, "job/#{job_id}/batch/#{id}").and_return(restforce_response)

      Restforce::Bulk::Batch.find(job_id, id)
    end

    it "returns the batch initialized with the returned attributes" do
      allow_restforce_request(:get, "job/#{job_id}/batch/#{id}").and_return(restforce_response)

      batch = Restforce::Bulk::Batch.find(job_id, id)

      expect(batch.id).to                       eq(response_body.batchInfo.id)
      expect(batch.job_id).to                   eq(response_body.batchInfo.jobId)
      expect(batch.state).to                    eq(response_body.batchInfo.state)
      expect(batch.created_date).to             eq(response_body.batchInfo.createdDate)
      expect(batch.system_modstamp).to          eq(response_body.batchInfo.systemModstamp)
      expect(batch.number_records_processed).to eq(response_body.batchInfo.numberRecordsProcessed)
    end
  end

  describe "state" do
    let(:state)     { 'Queued' }
    subject(:batch) { described_class.new(state: state) }

    context "when it is 'Queued'" do
      let(:state) { 'Queued' }

      it { is_expected.to be_queued }
      it { is_expected.to_not be_in_progress }
      it { is_expected.to_not be_completed }
      it { is_expected.to_not be_failed }
      it { is_expected.to_not be_not_processed }
    end

    context "when it is 'InProgress'" do
      let(:state) { 'InProgress' }

      it { is_expected.to_not be_queued }
      it { is_expected.to be_in_progress }
      it { is_expected.to_not be_completed }
      it { is_expected.to_not be_failed }
      it { is_expected.to_not be_not_processed }
    end

    context "when it is 'Completed'" do
      let(:state) { 'Completed' }

      it { is_expected.to_not be_queued }
      it { is_expected.to_not be_in_progress }
      it { is_expected.to be_completed }
      it { is_expected.to_not be_failed }
      it { is_expected.to_not be_not_processed }
    end

    context "when it is 'Failed'" do
      let(:state) { 'Failed' }

      it { is_expected.to_not be_queued }
      it { is_expected.to_not be_in_progress }
      it { is_expected.to_not be_completed }
      it { is_expected.to be_failed }
      it { is_expected.to_not be_not_processed }
    end

    context "when it is 'Not Processed'" do
      let(:state) { 'Not Processed' }

      it { is_expected.to_not be_queued }
      it { is_expected.to_not be_in_progress }
      it { is_expected.to_not be_completed }
      it { is_expected.to_not be_failed }
      it { is_expected.to be_not_processed }
    end
  end

  describe "#results" do
    subject(:batch) { described_class.new(id: SecureRandom.hex(18), job_id: SecureRandom.hex(18)) }

    let(:results) do
      [
        { id: SecureRandom.hex(18), success: true, created: true },
        { id: SecureRandom.hex(18), success: false, created: false, error: "Some Error" },
        { id: SecureRandom.hex(18), success: true, created: true }
      ]
    end

    let(:raw_response_body) do
      build_bulk_xml(:results) do |xml|
        results.each do |result|
          xml.result do
            xml.id      result[:id]
            xml.success result[:success]
            xml.created result[:created]
            xml.error   result[:error]
          end
        end
      end
    end

    it "retrieves batch results from salesforce" do
      expect_restforce_request(:get, "job/#{batch.job_id}/batch/#{batch.id}/result").and_return(restforce_response)

      batch.results
    end

    it "properly returns result objects" do
      allow_restforce_request(:get, "job/#{batch.job_id}/batch/#{batch.id}/result").and_return(restforce_response)

      returned_results = batch.results
      expect(batch.results.size).to eq(results.size)

      expect(returned_results.map(&:id)     ).to eq(results.map { |result| result[:id] })
      expect(returned_results.map(&:success)).to eq(results.map { |result| result[:success].to_s })
      expect(returned_results.map(&:created)).to eq(results.map { |result| result[:created].to_s })
      expect(returned_results.map(&:error)  ).to eq(results.map { |result| result[:error] })
    end

    it "properly sets job_id on result objects" do
      allow_restforce_request(:get, "job/#{batch.job_id}/batch/#{batch.id}/result").and_return(restforce_response)

      returned_results = batch.results
      expect(batch.results.map(&:job_id)).to eq(results.size.times.map { batch.job_id })
    end

    it "properly sets batch_id on result objects" do
      allow_restforce_request(:get, "job/#{batch.job_id}/batch/#{batch.id}/result").and_return(restforce_response)

      returned_results = batch.results
      expect(batch.results.map(&:batch_id)).to eq(results.size.times.map { batch.id })
    end

    context "when there is only one result" do
      let(:results) do
        [
          { id: SecureRandom.hex(18), success: true, created: true }
        ]
      end

      it "properly returns result objects" do
        allow_restforce_request(:get, "job/#{batch.job_id}/batch/#{batch.id}/result").and_return(restforce_response)

        returned_results = batch.results
        expect(batch.results.size).to eq(results.size)

        expect(returned_results.map(&:id)     ).to eq(results.map { |result| result[:id] })
        expect(returned_results.map(&:success)).to eq(results.map { |result| result[:success].to_s })
        expect(returned_results.map(&:created)).to eq(results.map { |result| result[:created].to_s })
        expect(returned_results.map(&:error)  ).to eq(results.map { |result| result[:error] })
      end

      it "properly sets job_id on result objects" do
        allow_restforce_request(:get, "job/#{batch.job_id}/batch/#{batch.id}/result").and_return(restforce_response)

        returned_results = batch.results
        expect(batch.results.map(&:job_id)).to eq(results.size.times.map { batch.job_id })
      end

      it "properly sets batch_id on result objects" do
        allow_restforce_request(:get, "job/#{batch.job_id}/batch/#{batch.id}/result").and_return(restforce_response)

        returned_results = batch.results
        expect(batch.results.map(&:batch_id)).to eq(results.size.times.map { batch.id })
      end
    end

    context "when the returned XML is for a query operation" do
      let(:id) { SecureRandom.hex(18) }

      # The query results list is returned in a different way
      let(:raw_response_body) do
        build_bulk_xml('result-list') do |xml|
          xml.result id
        end
      end

      it "properly parses the returned XML, creating only one result, with the Id filled" do
        allow_restforce_request(:get, "job/#{batch.job_id}/batch/#{batch.id}/result").and_return(restforce_response)

        expect(batch.results.size).to eq(1)
        result = batch.results.first

        expect(result.id).to eq(id)
      end

      it "properly sets job_id on result objects" do
        allow_restforce_request(:get, "job/#{batch.job_id}/batch/#{batch.id}/result").and_return(restforce_response)

        result = batch.results.first
        expect(result.job_id).to eq(batch.job_id)
      end

      it "properly sets batch_id on result objects" do
        allow_restforce_request(:get, "job/#{batch.job_id}/batch/#{batch.id}/result").and_return(restforce_response)

        result = batch.results.first
        expect(result.job_id).to eq(batch.job_id)
      end
    end

    context "when content type is CSV" do
      let(:response_body) do
        ::CSV.parse(raw_response_body, headers: true)
      end

      let(:raw_response_body) do
        CSV.generate do |csv|
          csv << ["Id", "Success", "Created", "Error"]

          results.each do |result|
            csv << [result[:id], result[:success], result[:created], result[:error]]
          end
        end
      end

      it "properly returns result objects" do
        allow_restforce_request(:get, "job/#{batch.job_id}/batch/#{batch.id}/result").and_return(restforce_response)

        returned_results = batch.results
        expect(batch.results.size).to eq(results.size)

        expect(returned_results.map(&:id)     ).to eq(results.map { |result| result[:id] })
        expect(returned_results.map(&:success)).to eq(results.map { |result| result[:success].to_s })
        expect(returned_results.map(&:created)).to eq(results.map { |result| result[:created].to_s })
        expect(returned_results.map(&:error)  ).to eq(results.map { |result| result[:error] })
      end

      it "properly sets job_id on result objects" do
        allow_restforce_request(:get, "job/#{batch.job_id}/batch/#{batch.id}/result").and_return(restforce_response)

        returned_results = batch.results
        expect(batch.results.map(&:job_id)).to eq(results.size.times.map { batch.job_id })
      end

      it "properly sets batch_id on result objects" do
        allow_restforce_request(:get, "job/#{batch.job_id}/batch/#{batch.id}/result").and_return(restforce_response)

        returned_results = batch.results
        expect(batch.results.map(&:batch_id)).to eq(results.size.times.map { batch.id })
      end
    end
  end
end
