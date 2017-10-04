$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end

require 'bundler/setup'

Bundler.require
require 'restforce/bulk'
require 'securerandom'

ROOT_PATH = File.expand_path('../..', __FILE__)

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

  def build_bulk_xml(root, options={}, &block)
    Nokogiri::XML::Builder.new do |xml|
      xml.send(root, { xmlns: 'http://www.force.com/2009/06/asyncapi/dataload' }.merge(options), &block)
    end.to_xml(encoding: 'UTF-8')
  end

  def build_restforce_response(status, body)
    double(Faraday::Response, status: status, body: body)
  end
end

module FileHelpers
  def file_fixture(filename)
    File.join(ROOT_PATH, 'spec/file_fixtures', filename)
  end
end

module RandomHelpers
  def default_random
    @default_random ||= SecureRandom.hex
  end
end

RSpec.configure do |config|
  config.include FileHelpers
  config.include RandomHelpers
  config.include RestforceMockHelpers, mock_restforce: true

  config.before(:each, mock_restforce: true) do
    Restforce::Bulk.client = nil
    allow(Restforce).to receive(:new).and_return(restforce_client)
  end

  config.before(:each) do
    FileUtils.rm_rf File.join(ROOT_PATH, 'tmp', '*')
    FileUtils.mkdir_p File.join(ROOT_PATH, 'tmp')
  end

  config.before(:each, mock_random: true) do
    allow(SecureRandom).to receive(:hex).and_return(default_random)
  end
end
