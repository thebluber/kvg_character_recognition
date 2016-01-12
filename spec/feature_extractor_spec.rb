require 'spec_helper'
RSpec.describe KvgCharacterRecognition::FeatureExtractor do
  let(:feature_extractor){ KvgCharacterRecognition::FeatureExtractor }
  let(:direction_map){ KvgCharacterRecognition::Map }

  it "should return a heatmap of the points" do
    strokes = [[[1, 1], [2, 3], [3, 1]], [[2, 5], [5, 5], [6, 6], [6, 2]]]
    expect(feature_extractor.heatmap(strokes.flatten(1), 2, 8).to_a).to match_array([3, 1, 1, 2])
  end

  it "should decompose vector in 4 directions" do
    expect(feature_extractor.decompose([2, 2])).to match_array([0,2*Math.sqrt(2),0,0])
    expect(feature_extractor.decompose([2, -2])).to match_array([0,0,0,-2*Math.sqrt(2)])
  end

  it "should filter direction vector map correctly" do
    map = direction_map.new(3,3,[0,0,0,0])
    map[0,0] = [0, 1, 2, 0]
    map[0,1] = [1, 1, 0, 0]
    map[0,2] = [0, 1, 2, 2]
    map[1,0] = [0, 0, 0, 0]
    map[1,1] = [4, 2, 1, 1]
    map[1,2] = [0, 0, 0, 0]
    map[2,0] = [1, 2, 1, 0]
    map[2,1] = [2, 4, 0, 0]
    map[2,2] = [1, 1, 1, 1]

    filtered = direction_map.new(2,2,[0,0,0,0])
    filtered[0,0] = [3/8.0, 1/2.0, 9/16.0, 1/16.0]
    filtered[0,1] = [3/8.0, 1/2.0, 9/16.0, 9/16.0]
    filtered[1,0] = [3/4.0, 9/8.0, 5/16.0, 1/16.0]
    filtered[1,1] = [3/4.0, 7/8.0, 5/16.0, 5/16.0]

    expect(feature_extractor.spatial_weight_filter(map).to_a).to match_array(filtered.to_a)
  end
end


