require "spec_helper"

describe Restforce::Bulk::Middleware::ParseCsv do
  let(:body)               { "a,b,c\n1,2,3\n4,5,6" }
  let(:faraday_env)        { Faraday::Env.new :get, body }
  let(:app_response)       { double('response') }
  let(:app)                { double('app', call: app_response) }
  let(:headers)            { {} }
  let(:env)                { { request: {}, request_headers: {}, response_headers: {} } }
  let(:content_type_regex) { /\bcsv$/ }
  subject(:middleware)     { described_class.new(app, content_type: content_type_regex) }

  before do
    expect(app_response).to receive(:on_complete).and_yield(env).and_return(faraday_env)
  end

  describe "#call(env)" do
    it "properly calls the app" do
      expect(app).to receive(:call).with(env)
      middleware.call(env)
    end

    context "when response content type is not CSV" do
      let(:env) { { request: {}, request_headers: {}, response_headers: { 'Content-Type' => 'text/xml' }, body: body } }

      it "does not parses the response from the app" do
        middleware.call(env)

        expect(env[:body]).to eq(body)
      end
    end

    context "when response content type is not CSV" do
      let(:env) { { request: {}, request_headers: {}, response_headers: { 'Content-Type' => 'text/csv' }, body: body } }

      it "parses the response from the app" do
        middleware.call(env)

        expect(env[:body]).to eq(CSV.parse(body, headers: true))
      end
    end
  end
end
