$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end

require 'bundler/setup'

Bundler.require
require 'restforce/bulk'

module RestforceMockHelpers
  def restforce_client
    @restforce_client ||= double(Restforce, {
      authenticate!: true,
      middleware: double('Middleware', use: true, insert_after: true, response: true),
      options: { api_version: '29.0', oauth_token: SecureRandom.hex }
    })
  end

  def bulk_api_base_path
    "/services/async/#{restforce_client.options[:api_version]}"
  end

  def mime_type_for(content_type)
    Restforce::Bulk::MIME_TYPE_MAPPING[content_type.to_sym]
  end

  def mock_restforce_request(mock_type, method, path, data=nil, content_type=:xml, headers={})
    resulting_headers = {
      'Content-Type' => "#{mime_type_for(content_type)} ;charset=UTF-8"
    }.merge(headers)

    send(mock_type, restforce_client)
      .to receive(method)
      .with([bulk_api_base_path, path].join('/'), data, resulting_headers)
  end

  def allow_restforce_request(method, path, data=nil, content_type=:xml, headers={})
    mock_restforce_request(:allow, method, path, data, content_type, headers)
  end

  def expect_restforce_request(method, path, data=nil, content_type=:xml, headers={})
    mock_restforce_request(:expect, method, path, data, content_type, headers)
  end

  def build_bulk_xml(root, &block)
    Nokogiri::XML::Builder.new do |xml|
      xml.send(root, xmlns: 'http://www.force.com/2009/06/asyncapi/dataload', &block)
    end.to_xml
  end

  def build_restforce_response(status, body)
    double(Faraday::Response, status: status, body: body)
  end
end

RSpec.configure do |config|
  config.include RestforceMockHelpers, mock_restforce: true

  config.before(:each, mock_restforce: true) do
    Restforce::Bulk.client = nil
    allow(Restforce).to receive(:new).and_return(restforce_client)
  end
end
