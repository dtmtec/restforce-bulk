require "spec_helper"

describe Restforce::Bulk::Job, mock_restforce: true do
  let(:object_name) { 'Account' }

  let(:raw_response_body) { '' }

  let(:response_body) do
    Restforce::Mash.new(::MultiXml.parse(raw_response_body))
  end

  let(:restforce_response) { build_restforce_response(200, response_body) }

  describe ".create(options)" do
    let(:operation)   { 'query' }
    let(:operation_content_type) { 'XML' }

    let(:xml_data) do
      build_bulk_xml(:jobInfo) do |xml|
        xml.operation operation
        xml.object object_name
        xml.contentType operation_content_type
      end
    end

    let(:raw_response_body) do
      build_bulk_xml(:jobInfo) do |xml|
        xml.id             SecureRandom.hex(18)
        xml.operation      operation
        xml.object         object_name
        xml.createdById    '005D0000001ALVFIA4'
        xml.createdDate    '2009-04-14T18:15:59.000Z'
        xml.systemModstamp '2009-04-14T18:15:59.000Z'
        xml.state          'Open'
        xml.contentType    operation_content_type
      end
    end

    it "creates a new job in salesforce" do
      expect_restforce_request(:post, 'job', xml_data).and_return(restforce_response)
      Restforce::Bulk::Job.create(operation, object_name)
    end

    it "returns a new job instance" do
      allow_restforce_request(:post, 'job', xml_data).and_return(restforce_response)

      job = Restforce::Bulk::Job.create(operation, object_name)
      expect(job).to be_a(Restforce::Bulk::Job)
    end

    it "properly initializes the job with the returned attributes" do
      allow_restforce_request(:post, 'job', xml_data).and_return(restforce_response)

      job = Restforce::Bulk::Job.create(operation, object_name)
      expect(job.id).to              eq(response_body.jobInfo.id)
      expect(job.operation).to       eq(response_body.jobInfo.operation)
      expect(job.object).to          eq(response_body.jobInfo.object)
      expect(job.created_by_id).to   eq(response_body.jobInfo.createdById)
      expect(job.created_date).to    eq(response_body.jobInfo.createdDate)
      expect(job.system_modstamp).to eq(response_body.jobInfo.systemModstamp)
      expect(job.state).to           eq(response_body.jobInfo.state)
    end

    it "properly initializes content_type" do
      allow_restforce_request(:post, 'job', xml_data).and_return(restforce_response)

      job = Restforce::Bulk::Job.create(operation, object_name)
      expect(job.content_type).to eq(:xml)
    end
  end

  describe "#add_batch(data)" do
    let(:object_name) { 'Account' }
    let(:operation)   { 'query' }
    subject(:job) { described_class.new(id: 'ABC123', operation: operation, object: object_name) }

    let(:data) { "select Id from Account" }

    let(:raw_response_body) do
      build_bulk_xml(:batchInfo) do |xml|
        xml.id                     SecureRandom.hex(18)
        xml.jobId                  job.id
        xml.state                  'Queued'
        xml.createdDate            '2009-04-14T18:15:59.000Z'
        xml.systemModstamp         '2009-04-14T18:15:59.000Z'
        xml.state                  'Open'
        xml.numberRecordsProcessed 0
      end
    end

    context "when operation is 'query'" do
      it "creates the batch in salesforce" do
        expect_restforce_request(:post, "job/#{job.id}/batch", data).and_return(restforce_response)

        job.add_batch(data)
      end

      it "properly initializes the batch with the returned attributes" do
        allow_restforce_request(:post, "job/#{job.id}/batch", data).and_return(restforce_response)

        batch = job.add_batch(data)
        expect(batch.id).to                       eq(response_body.batchInfo.id)
        expect(batch.job_id).to                   eq(response_body.batchInfo.jobId)
        expect(batch.state).to                    eq(response_body.batchInfo.state)
        expect(batch.created_date).to             eq(response_body.batchInfo.createdDate)
        expect(batch.system_modstamp).to          eq(response_body.batchInfo.systemModstamp)
        expect(batch.number_records_processed).to eq(response_body.batchInfo.numberRecordsProcessed)
      end

      it "adds the batch to the batches list" do
        allow_restforce_request(:post, "job/#{job.id}/batch", data).and_return(restforce_response)

        batch = job.add_batch(data)
        expect(job.batches).to include(batch)
      end
    end
  end
end
