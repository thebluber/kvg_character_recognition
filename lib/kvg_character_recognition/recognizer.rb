require 'matrix'
module KvgCharacterRecognition
  #This class contains methods calculating similarity scores between input pattern and template patterns
  module Recognizer

    #This method selects all templates from the database which should be further examined
    #It filtered out those characters with a too great difference in number of points and strokes to the input character
    def self.select_templates character, datastore
      p_min = character.number_of_points - 100
      p_max = character.number_of_points + 100
      s_min = character.number_of_strokes - 12
      s_max = character.number_of_strokes + 12
      datastore.characters_in_range(p_min..p_max, s_min..s_max)
    end

    #This method calculates similarity scores which is an average of the somehow weighted sum of the euclidean distance of
    #1. 20x20 smoothed heatmap
    #2. euclidean distance of directional feature densities in average
    #Params:
    #+strokes+:: strokes are not preprocessed
    #+datastore+:: JSONDatastore or custom datastore type having method characters_in_stroke_range(min..max)
    def self.scores strokes, datastore
      character = Trainer::Character.new(strokes, nil)
      templates = select_templates character, datastore

      scores = templates.map do |cand|

        heatmap_bi_moment_score = Math.manhattan_distance(cand[:heatmap_smoothed_granular], character.heatmap_smoothed_granular)
        heatmap_line_density_score = Math.manhattan_distance(cand[:heatmap_smoothed_coarse], character.heatmap_smoothed_coarse)
        heatmap_bi_moment_slant_score = Math.manhattan_distance(cand[:heatmap_smoothed_granular_with_slant], character.heatmap_smoothed_granular_with_slant)
        heatmap_line_density_slant_score = Math.manhattan_distance(cand[:heatmap_smoothed_coarse_with_slant], character.heatmap_smoothed_coarse_with_slant)


        [[heatmap_bi_moment_score, heatmap_line_density_score, heatmap_bi_moment_slant_score, heatmap_line_density_slant_score].min, cand]
      end

      scores.sort{ |a, b| a[0] <=> b[0] }
    end

  end
end
