require 'spec_helper'

RSpec.describe KvgCharacterRecognition::Preprocessor do
  let(:preprocessor) { KvgCharacterRecognition::Preprocessor }

  it "should interpolate points" do
    expect(preprocessor.interpolate([[1,1], [1,1.2], [1,2]], 0.5)).to match_array([[1, 1], [1, 1.5], [1, 2.0]])
    expect(preprocessor.interpolate([[0,1], [0.5,1], [1,1]],0.5)).to match_array([[0, 1], [0.5, 1.0], [1.0, 1.0]])
  end

  it "should downsample in regular interval" do
    stroke = [[1,1], [2,2], [3,3], [4,4], [5,5], [6,6]]
    expect(preprocessor.downsample(stroke, 2)).to match_array([[1,1], [3,3], [5,5]])
    expect(preprocessor.downsample(stroke, 3)).to match_array([[1,1], [4,4]])
  end

  it "should smooth a sequence with given weight" do
    #weight = [1,3,1]
    sequence = [[0,0], [2,2], [1,1], [0,0], [1,1]]
    expect(preprocessor.smooth(sequence)).to match_array([[0,0], [1.4,1.4], [1.0,1.0], [0.4,0.4], [1,1]])
  end

  it "should return means and diffs of given strokes" do
    strokes = [[[1,1], [2,2]], [[3,3], [1,3]]]
    means, diffs = preprocessor.means_and_diffs strokes
    expect(means).to match_array([1.75, 2.25])
    expect(diffs[0]).to match_array([-0.75, 0.25, 1.25, -0.75])
    expect(diffs[1]).to match_array([-1.25, -0.25, 0.75, 0.75])
  end

  it "should normalize with stroke using bi moment normalization" do
    strokes = [[[103, 157], [112, 158], [120, 157], [128, 156], [136, 155], [145, 153],
                [154, 152], [164, 151], [173, 150], [183, 149], [191, 148], [199, 148]],
               [[208, 147], [216, 146], [224, 145], [232, 144], [242, 143], [248, 142],
                [253, 141], [258, 141], [262, 140], [268, 140], [274, 139], [279, 138]]]
    normed = [[[10, 94], [14, 98], [17, 94], [21, 90], [25, 85], [29, 77],
               [33, 73], [38, 68], [42, 64], [46, 60], [50, 56], [54, 56]],
              [[58, 51], [63, 47], [67, 42], [71, 38], [77, 33], [80, 28],
               [82, 24], [85, 24], [87, 19], [91, 19], [94, 15], [96, 10]]]
    means, diffs = preprocessor.means_and_diffs strokes
    expect(preprocessor.bi_moment_normalize(means, diffs, strokes).map{|stroke| stroke.map{|p| p.map(&:floor) } }).to match_array normed
  end
end


