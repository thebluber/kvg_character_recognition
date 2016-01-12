# KvgCharacterRecognition
KvgCharacterRecognition module contains a CJK-character recognition engine which uses pattern/template matching techniques to achieve recognitionof stroke-order and stroke-number free handwritten character patterns in the format [stroke1, stroke2 ...].
A stroke is an array of points in the format [[x1, y1], [x2, y2], ...].
For templates, we use svg data from the [KanjiVG project](http://kanjivg.tagaini.net/)

The engine takes 3 steps to perform the recognition of an input pattern.
1. Preprocessing
The preprocessing step consists of smoothing, normalizing, interpolating and downsampling of the data points.
2. Feature Extraction
Smoothed heatmap, significant points and directional feature densities are used as features.
A heatmap divides the input pattern in small grids and stores the number of data points in each grid.
Significant points are defined as start and end point of a stroke, points on curve or edge.
Directional feature densities are introduced in the paper "On-line Recognition of Freely Handwritten Japanese Character Using Directional Feature Density"
3. Matching
We use the significant points to perform a coarse recognition of the input pattern, that filters out template patterns with great distance to the input pattern. Next, a mixed distance score of directional feature density and smoothed heatmap is calculated.
## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kvg_character_recognition'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kvg_character_recognition

## Usage

1. Create a database(e.g. using sqlite3 data.db)

2. Setup the characters table in the database and populate it with kanjivg templates from the [xml release](https://github.com/KanjiVG/kanjivg/releases)
```ruby
require 'kvg_character_recognition'

KvgCharacterRecognition::Database.setup

KvgCharacterRecognition::Database.populate_from_xml "kanjivg-20150615-2.xml"
```

3. Recognition

Use an input field of size 300x300 for the best recognition accuracy. The input pattern in the example is the character 二, drawn on a 300x300 html canvas using mouse.
```ruby
strokes = [[[99.0, 108.0], [100.0, 108.0], [101.0, 108.0], [101.0, 108.0], [103.0, 108.0], [105.0, 107.0], [107.0, 107.0], [108.0, 107.0], [111.0, 106.0], [111.0, 106.0], [112.0, 106.0], [113.0, 106.0], [114.0, 106.0], [115.0, 105.0], [116.0, 105.0], [118.0, 105.0], [120.0, 105.0], [121.0, 104.0], [122.0, 104.0], [122.0, 104.0], [123.0, 104.0], [124.0, 103.0], [125.0, 103.0], [126.0, 103.0], [127.0, 103.0], [129.0, 102.0], [130.0, 102.0], [132.0, 102.0], [132.0, 101.0], [133.0, 101.0], [135.0, 101.0], [136.0, 101.0], [137.0, 101.0], [138.0, 101.0], [140.0, 101.0], [141.0, 100.0], [142.0, 100.0], [143.0, 100.0], [144.0, 100.0], [145.0, 99.0], [148.0, 99.0], [150.0, 99.0], [151.0, 98.0], [152.0, 98.0], [153.0, 98.0], [154.0, 98.0], [156.0, 97.0], [157.0, 97.0], [158.0, 97.0], [159.0, 97.0], [161.0, 97.0], [162.0, 96.0], [162.0, 96.0], [164.0, 96.0], [165.0, 96.0], [166.0, 96.0], [167.0, 96.0], [169.0, 95.0], [170.0, 95.0], [171.0, 95.0], [172.0, 95.0], [173.0, 95.0], [174.0, 95.0]], [[53.0, 190.0], [54.0, 190.0], [56.0, 190.0], [57.0, 190.0], [59.0, 190.0], [61.0, 190.0], [63.0, 189.0], [66.0, 189.0], [67.0, 189.0], [68.0, 189.0], [69.0, 189.0], [71.0, 189.0], [72.0, 188.0], [72.0, 188.0], [74.0, 188.0], [76.0, 187.0], [78.0, 187.0], [80.0, 187.0], [81.0, 187.0], [82.0, 186.0], [84.0, 186.0], [87.0, 186.0], [89.0, 185.0], [91.0, 185.0], [93.0, 185.0], [95.0, 184.0], [98.0, 184.0], [100.0, 183.0], [102.0, 183.0], [104.0, 183.0], [106.0, 183.0], [110.0, 182.0], [111.0, 182.0], [112.0, 182.0], [115.0, 182.0], [118.0, 182.0], [120.0, 182.0], [122.0, 182.0], [125.0, 182.0], [128.0, 181.0], [130.0, 181.0], [133.0, 180.0], [136.0, 180.0], [141.0, 180.0], [143.0, 179.0], [146.0, 179.0], [150.0, 179.0], [152.0, 178.0], [155.0, 178.0], [158.0, 178.0], [159.0, 178.0], [162.0, 177.0], [164.0, 177.0], [167.0, 177.0], [170.0, 177.0], [173.0, 176.0], [176.0, 176.0], [179.0, 176.0], [182.0, 175.0], [187.0, 175.0], [189.0, 174.0], [192.0, 174.0], [194.0, 174.0], [196.0, 173.0], [199.0, 173.0], [202.0, 173.0], [204.0, 172.0], [206.0, 172.0], [209.0, 172.0], [211.0, 172.0], [212.0, 172.0], [215.0, 172.0], [217.0, 172.0], [219.0, 171.0], [221.0, 171.0], [221.0, 172.0]]]

scores = KvgCharacterRecognition::Recognizer.scores strokes

irb(main):004:0> scores.take 10
=> [[1.524079282599697, 60, "二"], [2.8346163809971143, 1373, "工"], [3.0987422100694757, 7, "上"], [3.127346308294038, 365, "冫"], [3.439293212191952, 6, "三"], [3.4890481845638304, 3770, "立"], [3.541524904953307, 2721, "江"], [3.641178875851016, 569, "厂"], [3.6447144433336294, 72, "亠"], [3.7498483818966353, 2706, "氵"]]
```

## Configuration
You can try out different parameters for adapting the extracted features to your input settings i.e. other sample rate, size
Don't forget to redo the whole database step after changing the configuration.
```ruby
  #this is the default configuration
  config = {
    size: 109, #fixed canvas size of kanjivg data
    downsample_interval: 4,
    interpolate_distance: 0.8,
    direction_grid: 15,
    smoothed_heatmap_grid: 20,
    significant_points_heatmap_grid: 3
  }

  #from hash
  Kvgcharacterrecognition.configure(config)
  #from yaml file
  Kvgcharacterrecognition.configure_with(path_to_yml)

  #configure database with yml
  #TODO why is postgres slower than sqlite?
  Kvgcharacterrecognition.configure_database(path_to_yml)
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/kvg_character_recognition.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

