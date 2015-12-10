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

    it "returns the job initialized with the returned attributes" do
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
end
