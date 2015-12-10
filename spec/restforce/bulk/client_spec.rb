require "spec_helper"

describe Restforce::Bulk::Client do
  let(:restforce_client) { double(Restforce, authenticate!: true, middleware: double('Middleware', insert_after: true, response: true), options: {}) }

  it "uses a default client connection" do
    allow(Restforce).to receive(:new).with(no_args).and_return(restforce_client)

    client = Restforce::Bulk::Client.new
    expect(client.connection).to eq(restforce_client)
  end

  it "ensures that the client is authenticated" do
    allow(Restforce).to receive(:new).with(no_args).and_return(restforce_client)
    expect(restforce_client).to receive(:authenticate!)

    client = Restforce::Bulk::Client.new
    client.connection
  end

  context "when a client is given" do
    let(:restforce_client) { Restforce.new(instance_url: 'test.salesforce.com') }

    it "uses it instead" do
      allow(restforce_client).to receive(:authenticate!)

      client = Restforce::Bulk::Client.new(restforce_client)
      expect(client.connection).to eq(restforce_client)
    end
  end

  describe "#perform_request(method, path, data=nil, content_type=:xml, headers={})", mock_restforce: true do
    subject(:client) { Restforce::Bulk::Client.new(restforce_client) }

    before do
      allow(Restforce).to receive(:new).with(no_args).and_return(restforce_client)
    end

    it "performs a get request using the given method, path and data" do
      expect_restforce_request(:get, 'some/path', 'some-data')

      client.perform_request(:get, 'some/path', 'some-data')
    end

    it "performs a post request using the given method, path and data" do
      expect_restforce_request(:post, 'some/other/path', { some: 'complex-data' })

      client.perform_request(:post, 'some/other/path', { some: 'complex-data' })
    end

    it "allows one to use a differente content type for the request" do
      expect_restforce_request(:post, 'some/other/path', { some: 'complex-data' }, :csv)

      client.perform_request(:post, 'some/other/path', { some: 'complex-data' }, :csv)
    end

    it "allows one to pass additional headers" do
      expect_restforce_request(:post, 'some/other/path', { some: 'complex-data' }, :csv, { some: 'header' })

      client.perform_request(:post, 'some/other/path', { some: 'complex-data' }, :csv, { some: 'header' })
    end
  end
end
