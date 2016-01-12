require 'matrix'
module KvgCharacterRecognition
  #This class contains methods calculating similarity scores between input pattern and template patterns
  class Recognizer

    #This method selects all templates from the database which should be further examined
    #It filtered out those characters with a too great difference in number of strokes to the input character
    def self.select_templates strokes
      min = strokes.count <= 5 ? strokes.count : strokes.count - 5
      max = strokes.count + 10
      KvgCharacterRecognition.db[:characters].where(:number_of_strokes => (min..max))
    end

    #This method uses heatmap of significant points to coarse recognize the input pattern
    #Params:
    #+strokes+:: strokes should be preprocessed
    def self.coarse_recognize strokes
      heatmap = FeatureExtractor.heatmap(Preprocessor.significant_points(strokes), CONFIG[:significant_points_heatmap_grid], CONFIG[:size]).to_a

      templates = select_templates strokes
      templates.map do |candidate|
        candidate_heatmap = candidate[:heatmap_significant_points].split(",").map(&:to_f)

        score = Preprocessor.euclidean_distance(heatmap, candidate_heatmap)
        [score.round(3), candidate]
      end
    end

    #This method calculates similarity scores which is an average of the somehow weighted sum of the euclidean distance of
    #1. 20x20 smoothed heatmap
    #2. euclidean distance of directional feature densities in average
    #Params:
    #+strokes+:: strokes are not preprocessed
    def self.scores strokes
      #preprocess strokes
      #with smoothing
      strokes = Preprocessor.preprocess(strokes, CONFIG[:interpolate_distance], CONFIG[:downsample_interval], true)

      #feature extraction
      directions = Matrix.columns(FeatureExtractor.spatial_weight_filter(FeatureExtractor.directional_feature_densities(strokes, CONFIG[:direction_grid])).to_a).to_a
      heatmap_smoothed = FeatureExtractor.smooth_heatmap(FeatureExtractor.heatmap(strokes.flatten(1), CONFIG[:smoothed_heatmap_grid], CONFIG[:size])).to_a

      #dump half of the templates after coarse recognition
      #collection is in the form [[score, c1], [score, c2] ...]
      collection = coarse_recognize(strokes).sort{ |a, b| a[0] <=> b[0] }

      scores = collection.take(collection.count / 2).map do |cand|
        direction_score = (Preprocessor.euclidean_distance(directions[0], cand[1][:direction_e1].split(",").map(&:to_f)) +
                           Preprocessor.euclidean_distance(directions[1], cand[1][:direction_e2].split(",").map(&:to_f)) +
                           Preprocessor.euclidean_distance(directions[2], cand[1][:direction_e3].split(",").map(&:to_f)) +
                           Preprocessor.euclidean_distance(directions[3], cand[1][:direction_e4].split(",").map(&:to_f)) ) / 4

        heatmap_score = Preprocessor.euclidean_distance(heatmap_smoothed, cand[1][:heatmap_smoothed].split(",").map(&:to_f))

        mix = (direction_score / 100) + heatmap_score
        [mix/2, cand[1][:id], cand[1][:value]]
      end

      scores.sort{ |a, b| a[0] <=> b[0] }
    end

  end
end
