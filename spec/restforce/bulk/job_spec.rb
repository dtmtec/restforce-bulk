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
    let(:object_name)  { 'Account' }
    let(:operation)    { 'query' }
    let(:content_type) { 'XML' }
    subject(:job) { described_class.new(id: 'ABC123', operation: operation, object: object_name, content_type: content_type) }

    let(:data) { "select Id from Account" }
    let(:post_data) { data }

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
        expect_restforce_request(:post, "job/#{job.id}/batch", post_data).and_return(restforce_response)

        job.add_batch(data)
      end

      it "properly initializes the batch with the returned attributes" do
        allow_restforce_request(:post, "job/#{job.id}/batch", post_data).and_return(restforce_response)

        batch = job.add_batch(data)
        expect(batch.id).to                       eq(response_body.batchInfo.id)
        expect(batch.job_id).to                   eq(response_body.batchInfo.jobId)
        expect(batch.state).to                    eq(response_body.batchInfo.state)
        expect(batch.created_date).to             eq(response_body.batchInfo.createdDate)
        expect(batch.system_modstamp).to          eq(response_body.batchInfo.systemModstamp)
        expect(batch.number_records_processed).to eq(response_body.batchInfo.numberRecordsProcessed)
      end

      it "adds the batch to the batches list" do
        allow_restforce_request(:post, "job/#{job.id}/batch", post_data).and_return(restforce_response)

        batch = job.add_batch(data)
        expect(job.batches).to include(batch)
      end

      context "when job content type is CSV" do
        let(:content_type) { 'CSV' }

        it "creates the batch in salesforce, with the proper content type" do
          expect_restforce_request(:post, "job/#{job.id}/batch", data, :csv).and_return(restforce_response)

          job.add_batch(data)
        end
      end
    end

    shared_examples_for "crud batch" do
      let(:data) { [{ Name: 'Some Name', Description: 'Desc 1' }, { Name: 'Some Other Name', Description: 'Desc 1' }] }

      let(:post_data) do
        build_bulk_xml(:sObjects) do |xml|
          data.each do |item|
            xml.sObject do
              item.each do |attr, value|
                xml.send(attr, value)
              end
            end
          end
        end
      end

      it "creates the batch in salesforce" do
        expect_restforce_request(:post, "job/#{job.id}/batch", post_data).and_return(restforce_response)

        job.add_batch(data)
      end

      it "properly initializes the batch with the returned attributes" do
        allow_restforce_request(:post, "job/#{job.id}/batch", post_data).and_return(restforce_response)

        batch = job.add_batch(data)
        expect(batch.id).to                       eq(response_body.batchInfo.id)
        expect(batch.job_id).to                   eq(response_body.batchInfo.jobId)
        expect(batch.state).to                    eq(response_body.batchInfo.state)
        expect(batch.created_date).to             eq(response_body.batchInfo.createdDate)
        expect(batch.system_modstamp).to          eq(response_body.batchInfo.systemModstamp)
        expect(batch.number_records_processed).to eq(response_body.batchInfo.numberRecordsProcessed)
      end

      it "adds the batch to the batches list" do
        allow_restforce_request(:post, "job/#{job.id}/batch", post_data).and_return(restforce_response)

        batch = job.add_batch(data)
        expect(job.batches).to include(batch)
      end

      context "when job content type is CSV" do
        let(:content_type) { 'CSV' }

        let(:post_data) do
          CSV.generate do |csv|
            csv << data.first.keys

            data.each do |attributes|
              csv << attributes.values
            end
          end
        end

        it "creates the batch in salesforce, with the proper content type" do
          expect_restforce_request(:post, "job/#{job.id}/batch", post_data, :csv).and_return(restforce_response)

          job.add_batch(data)
        end
      end
    end

    context "when operation is 'insert'" do
      it_behaves_like "crud batch" do
        let(:operation) { 'insert' }
      end
    end

    context "when operation is 'update'" do
      it_behaves_like "crud batch" do
        let(:operation) { 'update' }
      end
    end

    context "when operation is 'upsert'" do
      it_behaves_like "crud batch" do
        let(:operation) { 'upsert' }
      end
    end

    context "when operation is 'delete'" do
      it_behaves_like "crud batch" do
        let(:operation) { 'delete' }
      end
    end
  end
end
