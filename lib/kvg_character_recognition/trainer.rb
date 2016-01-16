module KvgCharacterRecognition
  module Trainer
    #This method populates the datastore with parsed template patterns from the kanjivg file in xml format
    #Params:
    #+xml+:: download the latest xml release from https://github.com/KanjiVG/kanjivg/releases
    #+datastore+:: JSONDatastore or custom datastore type having methods store, persist!
    def self.populate_from_xml xml, datastore
      file = File.open(xml) { |f| Nokogiri::XML(f) }

      file.xpath("//kanji").each do |kanji|
        #id has format: "kvg:kanji_CODEPOINT"
        codepoint = kanji.attributes["id"].value.split("_")[1]
        next unless codepoint.hex >= "04e00".hex && codepoint.hex <= "09faf".hex
        puts codepoint
        value = [codepoint.hex].pack("U")

        #Preprocessing
        #--------------
        #parse strokes
        strokes = kanji.xpath("g//path").map{|p| p.attributes["d"].value }.map{ |stroke| KvgParser::Stroke.new(stroke).to_a }
        #strokes in the format [[[x1, y1], [x2, y2] ...], [[x2, y2], [x3, y3] ...], ...]
        strokes = Preprocessor.preprocess(strokes, CONFIG[:interpolate_distance], CONFIG[:downsample_interval], false)

        #serialize strokes
        serialized = strokes.map.with_index do |stroke, i|
          stroke.map{ |p| [i, p[0], p[1]] }
        end

        points = strokes.flatten(1)

        #Feature Extraction
        #--------------
        #20x20 heatmap smoothed
        heatmap_smoothed = FeatureExtractor.smooth_heatmap(FeatureExtractor.heatmap(points, CONFIG[:smoothed_heatmap_grid], CONFIG[:size]))

        #directional feature densities
        #transposed from Mx4 to 4xM
        direction = Matrix.columns(FeatureExtractor.spatial_weight_filter(FeatureExtractor.directional_feature_densities(strokes, CONFIG[:direction_grid])).to_a).to_a

        #significant points
        significant_points = Preprocessor.significant_points(strokes)

        #3x3 heatmap of significant points for coarse recognition
        heatmap_significant_points = FeatureExtractor.heatmap(significant_points, CONFIG[:significant_points_heatmap_grid], CONFIG[:size])


        #Store to database
        #--------------
        character = {
          value: value,
          codepoint: codepoint.hex,
          number_of_strokes: strokes.count,
          serialized_strokes: serialized.join(","),
          direction_e1: direction[0].join(","),
          direction_e2: direction[1].join(","),
          direction_e3: direction[2].join(","),
          direction_e4: direction[3].join(","),
          heatmap_smoothed: heatmap_smoothed.to_a.join(","),
          heatmap_significant_points: heatmap_significant_points.to_a.join(",")
        }

        datastore.store character
      end

      datastore.persist!
    end
  end
end
