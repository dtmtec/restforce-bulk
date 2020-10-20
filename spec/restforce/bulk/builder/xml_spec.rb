require 'ostruct'
require "spec_helper"

describe Restforce::Bulk::Builder::Xml, mock_restforce: true do
  let(:builder) { Restforce::Bulk::Builder::Xml.new(:upsert) }

  def xml(field, value, tag = {})
    build_bulk_xml(:sObjects) do |builder|
      builder.sObject {
        builder.send(field, value, tag)
      }
    end
  end

  it "adds a nil=true tag to nil values" do
    payload = builder.generate([{IsActive: nil}])

    expect(payload).to eq(xml(:IsActive, nil, "xsi:nil" => true))
  end

  it "generates non-nil values" do
    payload = builder.generate([{IsActive: true}])

    expect(payload).to eq(xml(:IsActive, true))
  end

  it "generates false values" do
    payload = builder.generate([{IsActive: false}])

    expect(payload).to eq(xml(:IsActive, false))
  end
end
