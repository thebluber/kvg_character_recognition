module KvgCharacterRecognition
  module Trainer
    class Character
      attr_accessor :value,
        :number_of_strokes,
        :number_of_points,
        :strokes,
        :line_density_preprocessed_strokes,
        :line_density_preprocessed_strokes_with_slant,
        :bi_moment_preprocessed_strokes,
        :bi_moment_preprocessed_strokes_with_slant,
        :heatmap_smoothed_coarse,
        :heatmap_smoothed_granular,
        :heatmap_smoothed_coarse_with_slant,
        :heatmap_smoothed_granular_with_slant
      def initialize strokes, value
        @value = value
        @strokes = strokes
        @number_of_strokes = @strokes.count
        smooth = @value ? false : true
        bi_moment_normalized_strokes, bi_moment_normalized_strokes_with_slant = Preprocessor.bi_moment_normalize(@strokes)
        @bi_moment_preprocessed_strokes = Preprocessor.preprocess(bi_moment_normalized_strokes, CONFIG[:interpolate_distance], CONFIG[:downsample_interval], smooth)
        @bi_moment_preprocessed_strokes_with_slant = Preprocessor.preprocess(bi_moment_normalized_strokes_with_slant, CONFIG[:interpolate_distance], CONFIG[:downsample_interval], smooth)

        @number_of_points = @bi_moment_preprocessed_strokes.flatten(1).count

        line_density_normalized_strokes = Preprocessor.line_density_normalize(@bi_moment_preprocessed_strokes)
        @line_density_preprocessed_strokes = Preprocessor.preprocess(line_density_normalized_strokes, CONFIG[:interpolate_distance], CONFIG[:downsample_interval], true)
        line_density_normalized_strokes_with_slant = Preprocessor.line_density_normalize(@bi_moment_preprocessed_strokes_with_slant)
        @line_density_preprocessed_strokes_with_slant = Preprocessor.preprocess(line_density_normalized_strokes_with_slant, CONFIG[:interpolate_distance], CONFIG[:downsample_interval], true)

        @heatmap_smoothed_coarse = Preprocessor.smooth_heatmap(Preprocessor.heatmap(@line_density_preprocessed_strokes.flatten(1), CONFIG[:heatmap_coarse_grid], CONFIG[:size])).to_a
        @heatmap_smoothed_granular = Preprocessor.smooth_heatmap(Preprocessor.heatmap(@bi_moment_preprocessed_strokes.flatten(1), CONFIG[:heatmap_granular_grid], CONFIG[:size])).to_a

        @heatmap_smoothed_coarse_with_slant = Preprocessor.smooth_heatmap(Preprocessor.heatmap(@line_density_preprocessed_strokes_with_slant.flatten(1), CONFIG[:heatmap_coarse_grid], CONFIG[:size])).to_a
        @heatmap_smoothed_granular_with_slant = Preprocessor.smooth_heatmap(Preprocessor.heatmap(@bi_moment_preprocessed_strokes_with_slant.flatten(1), CONFIG[:heatmap_granular_grid], CONFIG[:size])).to_a

      end
    end

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

        chr = Character.new strokes, value

        #Store to database
        #--------------
        character = {
          value: value,
          codepoint: codepoint.hex,
          number_of_strokes: strokes.count,
          number_of_points: chr.number_of_points,
          heatmap_smoothed_coarse: chr.heatmap_smoothed_coarse,
          heatmap_smoothed_granular: chr.heatmap_smoothed_granular,
          heatmap_smoothed_coarse_with_slant: chr.heatmap_smoothed_coarse_with_slant,
          heatmap_smoothed_granular_with_slant: chr.heatmap_smoothed_granular_with_slant
        }

        datastore.store character
      end

      datastore.persist!
    end
  end
end
