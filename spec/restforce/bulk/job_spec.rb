require "spec_helper"

describe Restforce::Bulk::Job, mock_restforce: true do
  let(:object_name) { 'Account' }
  let(:external_id_field) { 'Name' }

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

    let(:xml_upsert) do
      build_bulk_xml(:jobInfo) do |xml|
        xml.operation operation
        xml.object object_name
        xml.externalIdFieldName external_id_field
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

    context "when content type is passed as :csv" do
      let(:operation_content_type) { 'CSV' }

      it "properly initializes content_type" do
        allow_restforce_request(:post, 'job', xml_data).and_return(restforce_response)

        job = Restforce::Bulk::Job.create(operation, object_name, :csv)
        expect(job.content_type).to eq(:csv)
      end
    end

    context "with external_id" do
      let(:operation) { 'upsert' }

      it "adds an external id to xml if there is an external_id" do
        expect_restforce_request(:post, "job", xml_upsert).and_return(restforce_response)

        job = Restforce::Bulk::Job.create(operation, object_name, :xml, 'Name')
      end
    end
  end

  describe ".find(id)" do
    let(:id) { SecureRandom.hex(18) }

    let(:operation_content_type) { 'XML' }

    let(:raw_response_body) do
      build_bulk_xml(:jobInfo) do |xml|
        xml.id             id
        xml.operation      'update'
        xml.object         'Lead'
        xml.createdById    '005D0000001ALVFIA4'
        xml.createdDate    '2009-04-14T18:15:59.000Z'
        xml.systemModstamp '2009-04-14T18:15:59.000Z'
        xml.state          'Closed'
        xml.contentType    operation_content_type
      end
    end

    it "retrieves job info from salesforce using the given id" do
      expect_restforce_request(:get, "job/#{id}").and_return(restforce_response)

      job = Restforce::Bulk::Job.find(id)
    end

    it "returns the job initialized with the returned attributes" do
      allow_restforce_request(:get, "job/#{id}").and_return(restforce_response)

      job = Restforce::Bulk::Job.find(id)

      expect(job.id).to              eq(response_body.jobInfo.id)
      expect(job.operation).to       eq(response_body.jobInfo.operation)
      expect(job.object).to          eq(response_body.jobInfo.object)
      expect(job.created_by_id).to   eq(response_body.jobInfo.createdById)
      expect(job.created_date).to    eq(response_body.jobInfo.createdDate)
      expect(job.system_modstamp).to eq(response_body.jobInfo.systemModstamp)
      expect(job.state).to           eq(response_body.jobInfo.state)
    end

    it "properly initializes content_type" do
      allow_restforce_request(:get, "job/#{id}").and_return(restforce_response)

      job = Restforce::Bulk::Job.find(id)
      expect(job.content_type).to eq(:xml)
    end

    context "when content type is CSV" do
      let(:operation_content_type) { 'CSV' }

      it "properly initializes content_type" do
        allow_restforce_request(:get, "job/#{id}").and_return(restforce_response)

        job = Restforce::Bulk::Job.find(id)
        expect(job.content_type).to eq(:csv)
      end
    end
  end

  describe "#reload_batches" do
    subject(:job) { described_class.new(id: SecureRandom.hex(18)) }

    let(:batches) do
      [
        { id: SecureRandom.hex(18), job_id: job.id, state: 'Queued' },
        { id: SecureRandom.hex(18), job_id: job.id, state: 'InProgress' },
        { id: SecureRandom.hex(18), job_id: job.id, state: 'Completed' },
      ]
    end

    # Salesforce Bulk API does not return the response with a proper content-type
    # so we need to force XML parsing for this
    let(:response_body) do
      raw_response_body
    end

    let(:raw_response_body) do
      build_bulk_xml(:batchInfoList) do |xml|
        batches.each do |batch|
          xml.batchInfo do
            xml.id             batch[:id]
            xml.jobId          batch[:job_id]
            xml.state          batch[:state]
          end
        end
      end
    end

    it "retrieves information for job batches from salesforce" do
      expect_restforce_request(:get, "job/#{job.id}/batch").and_return(restforce_response)

      job.reload_batches
    end

    it "properly populates batches" do
      allow_restforce_request(:get, "job/#{job.id}/batch").and_return(restforce_response)

      job.reload_batches

      expect(job.batches.size).to eq(batches.size)

      expect(job.batches.map(&:id)).to eq(batches.map { |batch| batch[:id] })
    end

    context "when only one batch is returned" do
      let(:batches) do
        [
          { id: SecureRandom.hex(18), job_id: job.id, state: 'Queued' }
        ]
      end

      it "properly populates batches" do
        allow_restforce_request(:get, "job/#{job.id}/batch").and_return(restforce_response)

        job.reload_batches

        expect(job.batches.size).to eq(1)
      end
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

      context "and the batch is a binary attachment" do
        let(:data) { [{ full_filename: file_fixture('attachments/image.jpg'), filename: 'image.jpg', parent_id: 'ABC123' }, { full_filename: file_fixture('attachments/subfolder/image.jpg'), filename: 'subfolder/image.jpg', parent_id: 'DEF987' }] }
        let(:content_type) { :zip_xml }

        let(:zipper) { Restforce::Bulk::Zipper.new(data, content_type) }

        let(:post_data) do
          File.read(zipper.zip)
        end

        it "creates the batch in salesforce" do
          expect_restforce_request(:post, "job/#{job.id}/batch", post_data, content_type).and_return(restforce_response)

          job.add_batch(data)
        end

        it "properly initializes the batch with the returned attributes" do
          allow_restforce_request(:post, "job/#{job.id}/batch", post_data, content_type).and_return(restforce_response)

          batch = job.add_batch(data)
          expect(batch.id).to                       eq(response_body.batchInfo.id)
          expect(batch.job_id).to                   eq(response_body.batchInfo.jobId)
          expect(batch.state).to                    eq(response_body.batchInfo.state)
          expect(batch.created_date).to             eq(response_body.batchInfo.createdDate)
          expect(batch.system_modstamp).to          eq(response_body.batchInfo.systemModstamp)
          expect(batch.number_records_processed).to eq(response_body.batchInfo.numberRecordsProcessed)
        end

        it "adds the batch to the batches list" do
          allow_restforce_request(:post, "job/#{job.id}/batch", post_data, content_type).and_return(restforce_response)

          batch = job.add_batch(data)
          expect(job.batches).to include(batch)
        end

        context "when content type is zip/csv" do
          let(:content_type) { :zip_csv }

          it "properly creates the batch in salesforce using the given content type" do
            expect_restforce_request(:post, "job/#{job.id}/batch", post_data, content_type).and_return(restforce_response)

            job.add_batch(data)
          end
        end
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

  describe "#close" do
    subject(:job) { described_class.new(id: 'ABC123', state: 'Open') }

    let(:post_data) do
      build_bulk_xml(:jobInfo) do |xml|
        xml.state 'Closed'
      end
    end

    let(:raw_response_body) do
      build_bulk_xml(:jobInfo) do |xml|
        xml.id             job.id
        xml.operation      'upsert'
        xml.object         'Lead'
        xml.createdById    '005D0000001ALVFIA4'
        xml.createdDate    '2009-04-14T18:15:59.000Z'
        xml.systemModstamp '2009-04-14T18:15:59.000Z'
        xml.state          'Closed'
        xml.contentType    'XML'
      end
    end

    it "closes the job in salesforce" do
      expect_restforce_request(:post, "job/#{job.id}", post_data).and_return(restforce_response)

      job.close
    end

    it "updates job with the returned data" do
      expect_restforce_request(:post, "job/#{job.id}", post_data).and_return(restforce_response)

      job.close
      expect(job.state).to eq('Closed')
    end
  end

  describe "#abort" do
    subject(:job) { described_class.new(id: 'ABC123', state: 'Open') }

    let(:post_data) do
      build_bulk_xml(:jobInfo) do |xml|
        xml.state 'Aborted'
      end
    end

    let(:raw_response_body) do
      build_bulk_xml(:jobInfo) do |xml|
        xml.id             job.id
        xml.operation      'upsert'
        xml.object         'Lead'
        xml.createdById    '005D0000001ALVFIA4'
        xml.createdDate    '2009-04-14T18:15:59.000Z'
        xml.systemModstamp '2009-04-14T18:15:59.000Z'
        xml.state          'Aborted'
        xml.contentType    'XML'
      end
    end

    it "aborts the job in salesforce" do
      expect_restforce_request(:post, "job/#{job.id}", post_data).and_return(restforce_response)

      job.abort
    end

    it "updates job with the returned data" do
      expect_restforce_request(:post, "job/#{job.id}", post_data).and_return(restforce_response)

      job.abort
      expect(job.state).to eq('Aborted')
    end
  end
end
