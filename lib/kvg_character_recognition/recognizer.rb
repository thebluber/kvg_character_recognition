module KvgCharacterRecognition
  #This class contains methods calculating similarity scores between input pattern and template patterns
  module Recognizer
    extend Trainer

    #This method selects all templates from the database which should be further examined
    #It filtered out those characters with a too great difference in number of points and strokes to the input character
    def select_templates datastore, number_of_points, number_of_strokes
      p_min = number_of_points - 100
      p_max = number_of_points + 100
      s_min = number_of_strokes - 12
      s_max = number_of_strokes + 12
      datastore.characters_in_range(p_min..p_max, s_min..s_max)
    end

    #This method calculates similarity scores which is an average of the somehow weighted sum of the euclidean distance of
    #1. 17x17 smoothed heatmap
    #2. manhattan distance of directional feature densities in average
    #Params:
    #+strokes+:: strokes are not preprocessed
    #+datastore+:: JSONDatastore or custom datastore type having method characters_in_stroke_range(min..max)
    def self.manhattan_heatmap_scores strokes, datastore
      strokes = preprocess(strokes)
      heatmaps = heatmaps(strokes)
      templates = select_templates datastore, @number_of_points, strokes.count

      #scores = datastore.data.map do |cand|
      scores = templates.map do |cand|
        score = Math.manhattan_distance(heatmaps[0], cand[:heatmaps][0]) +
                Math.manhattan_distance(heatmaps[1], cand[:heatmaps][1]) +
                Math.manhattan_distance(heatmaps[2], cand[:heatmaps][2])
        [score, cand]
      end

      scores.sort{ |a, b| a[0] <=> b[0] }
    end

  end
end
