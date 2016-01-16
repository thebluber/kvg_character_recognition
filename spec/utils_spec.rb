require 'spec_helper'

RSpec.describe "Utils" do
  context "KvgCharacterRecognition::Map" do
    it "should return size of map" do
      map = KvgCharacterRecognition::Map.new(4,4,0)
      expect(map.size).to eq 4
    end

    it "should generate a 3x3 heatmap" do
      heatmap = KvgCharacterRecognition::Map.new(3,3,0)
      expect(heatmap.to_a).to match_array [0, 0, 0, 0, 0, 0, 0, 0, 0]
      
      #store value to cell
      heatmap[0,0] = 1
      expect(heatmap[0,0]).to eq 1
      heatmap[1,2] = 3
      expect(heatmap[1,2]).to eq 3

      expect(heatmap.to_a).to match_array [1, 0, 0, 0, 0, 3, 0, 0, 0]
    end
  end

  it "should correctly calculate euclidean distance" do
    expect(Math.euclidean_distance([1,1], [1,2])).to eq 1
  end
end
