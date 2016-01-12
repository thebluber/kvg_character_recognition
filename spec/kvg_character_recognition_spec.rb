require 'spec_helper'

describe KvgCharacterRecognition do
  it 'has a version number' do
    expect(KvgCharacterRecognition::VERSION).not_to be nil
  end

  it 'has a database' do
    expect(KvgCharacterRecognition.db).not_to be nil
  end

  it 'has config parameters' do
    expect(KvgCharacterRecognition::CONFIG).not_to be nil
  end

  it "can config from yaml file" do
    new_config = {
      "size" => 100,
      "downsample_interval" => 5,
      "interpolate_distance" => 0.5,
      "direction_grid" => 13,
      "smoothed_heatmap_grid" => 21,
      "significant_points_heatmap_grid" => 2
    }
    expect(KvgCharacterRecognition).to receive(:configure).with(new_config).and_return({})
    KvgCharacterRecognition.configure_with(File.expand_path("spec/fixtures/config.yml"))
  end
end
