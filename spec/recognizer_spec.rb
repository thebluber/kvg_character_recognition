require 'spec_helper'
require 'pry'

RSpec.describe KvgCharacterRecognition::Recognizer do
  let(:recognizer) { KvgCharacterRecognition::Recognizer }
  let(:datastore) { KvgCharacterRecognition::JSONDatastore.new("spec/fixtures/characters.json") }
  let(:character) { KvgCharacterRecognition::Trainer::Character }
  
  it "should calculate scores given valid strokes and datastore" do
    #strokes belong to character "一"
    strokes = [[[107.0, 97.0], [108.0, 98.0], [109.0, 98.0], [111.0, 98.0], [112.0, 98.0], [114.0, 98.0], [119.0, 97.0], [123.0, 97.0], [125.0, 97.0], [128.0, 96.0], [131.0, 96.0], [134.0, 95.0], [136.0, 95.0], [140.0, 95.0], [142.0, 94.0], [145.0, 94.0], [148.0, 93.0], [150.0, 93.0], [152.0, 93.0], [153.0, 93.0], [154.0, 93.0], [156.0, 93.0], [158.0, 93.0], [160.0, 93.0], [161.0, 93.0], [163.0, 93.0], [165.0, 93.0], [166.0, 93.0], [168.0, 93.0], [170.0, 93.0], [172.0, 93.0], [173.0, 93.0], [175.0, 93.0], [177.0, 93.0], [178.0, 93.0], [179.0, 93.0], [181.0, 93.0], [182.0, 93.0], [183.0, 93.0], [185.0, 93.0], [187.0, 93.0], [188.0, 93.0], [189.0, 93.0], [190.0, 93.0], [192.0, 93.0], [193.0, 93.0], [194.0, 93.0], [196.0, 93.0], [199.0, 93.0], [200.0, 93.0], [201.0, 93.0], [203.0, 93.0], [204.0, 93.0], [206.0, 93.0], [207.0, 93.0], [208.0, 93.0], [210.0, 93.0], [211.0, 93.0], [212.0, 93.0], [214.0, 92.0], [215.0, 92.0], [216.0, 92.0], [218.0, 92.0], [219.0, 92.0], [220.0, 92.0], [222.0, 92.0], [223.0, 92.0], [224.0, 92.0], [226.0, 92.0], [229.0, 92.0], [232.0, 92.0], [233.0, 92.0], [234.0, 92.0], [235.0, 92.0], [236.0, 92.0], [237.0, 92.0]]]
    chr = character.new(strokes, nil)
    scores = recognizer.coarse_recognize(chr, datastore)
    expect(scores.count).to eq 5

    scores = recognizer.scores(strokes, datastore)
    expect(scores.count).to eq 2
    expect(scores.first[1][:value]).to eq "一"
  end

end
