require "spec_helper"

describe Restforce::Bulk::Middleware::Authorization do
  let(:app)            { double('app', call: nil) }
  let(:env)            { { request_headers: {}, response_headers: {} } }
  let(:options)        { { oauth_token: SecureRandom.hex } }
  let(:client)         { Restforce.new }
  subject(:middleware) { described_class.new(app, client, options) }

  describe "#call(env)" do
    it "properly calls the app" do
      expect(app).to receive(:call).with(env)
      middleware.call(env)
    end

    it "adds the 'X-SFDC-Session' header with the OAuth token" do
      middleware.call(env)
      expect(env[:request_headers]['X-SFDC-Session']).to eq(options[:oauth_token])
    end
  end
end
