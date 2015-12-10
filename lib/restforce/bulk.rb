require "multi_xml"
require "nokogiri"
require "restforce"
require "restforce/bulk/version"
require "active_support/inflector"

module Restforce
  module Bulk
    autoload :Client, 'restforce/bulk/client'
    autoload :Job,    'restforce/bulk/job'
    autoload :Batch,  'restforce/bulk/batch'

    autoload :Attributes, 'restforce/bulk/attributes'

    module Builder
      autoload :Xml, 'restforce/bulk/builder/xml'
      autoload :Csv, 'restforce/bulk/builder/csv'
    end

    MIME_TYPE_MAPPING = {
      csv: 'text/csv',
      xml: 'application/xml',
      zip_csv: 'zip/csv',
      zip_xml: 'zip/xml'
    }

    def self.client
      @client ||= Restforce::Bulk::Client.new
    end

    def self.client=(client)
      @client = client
    end
  end
end
