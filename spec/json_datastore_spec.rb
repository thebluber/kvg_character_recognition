require 'spec_helper'

RSpec.describe KvgCharacterRecognition::JSONDatastore do
  let(:datastore) { KvgCharacterRecognition::JSONDatastore }
  
  it "should parse json file with symbolized keys" do
    json = datastore.new("spec/fixtures/test_characters.json").instance_variable_get('@data')
    expect(json.count).to eq 3
    expect(json.first[:value]).to eq 'A'
    expect(json.first[:number_of_strokes]).to eq 2
  end

  it "should select characters in stroke range" do
    store = datastore.new("spec/fixtures/test_characters.json")
    expect(store.characters_in_stroke_range(1..2).count).to eq 2
  end
end
