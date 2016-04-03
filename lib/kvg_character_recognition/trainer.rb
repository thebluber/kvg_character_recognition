module KvgCharacterRecognition
  module Trainer
    @@config = { downsample_rate: 4,
                 interpolate_distance: 0.8,
                 size: 109,
                 smooth: true,
                 smooth_weights: [1,2,3,2,1],
                 smooth_filter_weights: [1/9.0, 1/9.0, 1/9.0, 1/9.0, 1/9.0, 1/9.0, 1/9.0, 1/9.0, 1/9.0],
                 heatmap_number_of_grids: 17
    }
    @@preprocessor = Preprocessor.new(@@config[:interpolate_distance],
                                      @@config[:size],
                                      @@config[:smooth],
                                      @@config[:smooth_weights])

    # this variable will be set in the method preprocess
    @number_of_points = 0

    # preprocess strokes and set the number_of_points variable
    # !the preprocessed strokes are not downsampled
    def preprocess strokes
      strokes = @@preprocessor.preprocess(strokes)
      @number_of_points = strokes.flatten(1).count
      strokes
    end

    # This method returns the 3x 17x17 direction feature vector
    # strokes are preprocessed
    def heatmaps strokes
      weights = @@config[:smooth_filter_weights]
      number_of_grids = @@config[:heatmap_number_of_grids]

      bi_normed = strokes
      ld_normed = @@preprocessor.line_density_normalize(bi_normed).map{ |stroke| downsample(stroke, @@config[:downsample_rate]) }
      pd_normed = @@preprocessor.point_density_normalize(bi_normed).map{ |stroke| downsample(stroke, @@config[:downsample_rate]) }
      bi_normed = bi_normed.map{ |stroke| downsample(stroke, @@config[:downsample_rate]) }

      # feature extraction
      heatmaps_map = HeatmapFeature.new(bi_normed,
                                        ld_normed,
                                        pd_normed,
                                        @@config[:size],
                                        number_of_grids,
                                        weights).heatmaps

      # convert to feature vector
      Matrix.columns(heatmaps_map.to_a).to_a
    end

    private
    #This methods downsamples a stroke in given interval
    #The number of points in the stroke will be reduced
    def downsample stroke, interval
      stroke.each_slice(interval).map(&:first)
    end

  end
end
