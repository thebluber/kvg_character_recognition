module KvgCharacterRecognition
  #This class has a collection of methods for the preprocessing step of character recognition
  class Preprocessor

    #A simple smooth method using the following formula
    #p'(i) = (w(-M)*p(i-M) + ... + w(0)*p(i) + ... + w(M)*p(i+M)) / S
    #where the smoothed point is a weighted average of its adjacent points.
    #Only the user input should be smoothed, it is not necessary for kvg data.
    #Params:
    #+stroke+:: array of points i.e [[x1, y1], [x2, y2] ...]
    def self.smooth stroke
      weights = [1,1,2,1,1]
      offset = weights.length / 2
      wsum = weights.inject{ |sum, x|  sum + x}

      return stroke if stroke.length < weights.length

      copy = stroke.dup

      (offset..(stroke.length - offset - 1)).each do |i|
        accum = [0, 0]

        weights.each_with_index do |w, j|
          accum[0] += w * copy[i + j - offset][0]
          accum[1] += w * copy[i + j - offset][1]
        end

        stroke[i] = accum.map{ |acc| (acc / wsum.to_f).round(2) }
      end
      stroke
    end

    #This method executes different preprocessing steps
    #strokes are normalized
    #1.Smooth strokes if set to true
    #2.Interpolate points by given distance, in order to equalize the sample rate of input and template
    #3.Downsample by given interval
    def self.preprocess strokes, interpolate_distance=0.8, downsample_interval=4, smooth=true
      strokes.map do |stroke|
        stroke = smooth(stroke) if smooth
        interpolated = smooth(interpolate(stroke, interpolate_distance))
        downsample(interpolated, downsample_interval)
      end
    end

    # accumulated histogram needed by line density normalization
    def self.accumulated_histogram points
      grids = CONFIG[:size] + 1
      h_x = []
      h_y = []
      (0..grids).each do |i|
        h_x[i] = points.count{ |p| p[0].round == i }
        h_y[i] = points.count{ |p| p[1].round == i }
        h_x[i] = h_x[i] + h_x[i - 1] if i > 0
        h_y[i] = h_y[i] + h_y[i - 1] if i > 0
      end

      [h_x, h_y]
    end

    # line density normalization
    def self.line_density_normalize strokes
      points = strokes.flatten(1)
      h_x, h_y = accumulated_histogram points
      strokes.map do |stroke|
        stroke.map do |point|
          [(CONFIG[:size] * h_x[point[0].round] / points.length.to_f).round(2), (CONFIG[:size] * h_y[point[1].round] / points.length.to_f).round(2)]
        end
      end
    end

    #This method calculates means and diffs of x and y coordinates in the strokes
    #The return values are used in the normalization step
    #means, diffs = means_and_diffs strokes
    #Return values:
    #+means+:: [mean_of_x, mean_of_y]
    #+diffs+:: differences of the x and y coordinates to their means i.e. [[d_x1, d_x2 ...], [d_y1, d_y2 ...]]
    def self.means_and_diffs strokes
      points = strokes.flatten(1)
      sums = points.inject([0, 0]){ |acc, point| acc = [acc[0] + point[0], acc[1] + point[1]] }
      #means = [x_c, y_c]
      means = sums.map{ |sum| (sum / points.length.to_f).round(2) }

      #for slant correction
      diff_x = []
      diff_y = []
      u11 = 0
      u02 = 0
      points.each do |point|
        diff_x << point[0] - means[0]
        diff_y << point[1] - means[1]

        u11 += (point[0] - means[0]) * (point[1] - means[1])
        u02 += (point[1] - means[1])**2
      end
      [means, [diff_x, diff_y], -1 * u11 / u02]
    end

    #This methods normalizes the strokes using bi moment
    #Params:
    #+strokes+:: [[[x1, y1], [x2, y2], ...], [[x1, y1], ...]]
    #+slant_correction+:: boolean whether a slant correction should be performed
    #returns normed_strokes, normed_strokes_with_slant_correction
    def self.bi_moment_normalize strokes
      means, diffs, slant_slope = means_and_diffs strokes

      #calculating delta values
      delta = Proc.new do |diff, operator|
        #d_x or d_y
        #operator: >= or <
        accum = 0
        counter = 0

        diff.each do |d|
          if d.send operator, 0
            accum += d ** 2
            counter += 1
          end
        end
        accum / counter
      end

      new_strokes = []
      new_strokes_with_slant = []

      strokes.each do |stroke|
        new_stroke = []
        new_stroke_slant = []
        stroke.each do |point|
          x = point[0]
          y = point[1]
          x_slant = x + (y - means[1]) * slant_slope

          if x - means[0] >= 0
            new_x = ( CONFIG[:size] * (x - means[0]) / (4 * Math.sqrt(delta.call(diffs[0], :>=))).round(2) ) + CONFIG[:size]/2
          else
            new_x = ( CONFIG[:size] * (x - means[0]) / (4 * Math.sqrt(delta.call(diffs[0], :<))).round(2) ) + CONFIG[:size]/2
          end
          if x_slant - means[0] >= 0
            new_x_slant = ( CONFIG[:size] * (x_slant - means[0]) / (4 * Math.sqrt(delta.call(diffs[0], :>=))).round(2) ) + CONFIG[:size]/2
          else
            new_x_slant = ( CONFIG[:size] * (x_slant - means[0]) / (4 * Math.sqrt(delta.call(diffs[0], :<))).round(2) ) + CONFIG[:size]/2
          end

          if y - means[1] >= 0
            new_y = ( CONFIG[:size] * (y - means[1]) / (4 * Math.sqrt(delta.call(diffs[1], :>=))).round(2) ) + CONFIG[:size]/2
          else
            new_y = ( CONFIG[:size] * (y - means[1]) / (4 * Math.sqrt(delta.call(diffs[1], :<))).round(2) ) + CONFIG[:size]/2
          end

          if new_x >= 0 && new_x <= CONFIG[:size] && new_y >= 0 && new_y <= CONFIG[:size]
            new_stroke << [new_x.round(3), new_y.round(3)]
          end
          if new_x_slant >= 0 && new_x_slant <= CONFIG[:size] && new_y >= 0 && new_y <= CONFIG[:size]
            new_stroke_slant << [new_x_slant.round(3), new_y.round(3)]
          end
        end
        new_strokes << new_stroke unless new_stroke.empty?
        new_strokes_with_slant << new_stroke_slant unless new_stroke_slant.empty?
      end
      [new_strokes, new_strokes_with_slant]
    end

    #This method interpolates points into a stroke with given distance
    #The algorithm is taken from the paper preprocessing techniques for online character recognition 
    def self.interpolate stroke, d=0.5
      current = stroke.first
      new_stroke = [current]

      index = 1
      last_index = 0
      while index < stroke.length do
        point = stroke[index]

        #only consider point with greater than d distance to current point
        if Math.euclidean_distance(current, point) < d
          index += 1
        else

          #calculate new point coordinate
          new_point = []
          if point[0].round(2) == current[0].round(2) # x2 == x1
            if point[1] > current[1] # y2 > y1
              new_point = [current[0], current[1] + d]
            else # y2 < y1
              new_point = [current[0], current[1] - d]
            end
          else # x2 != x1
            slope = (point[1] - current[1]) / (point[0] - current[0]).to_f
            if point[0] > current[0] # x2 > x1
              new_point[0] = current[0] + Math.sqrt(d**2 / (slope**2 + 1))
            else # x2 < x1
              new_point[0] = current[0] - Math.sqrt(d**2 / (slope**2 + 1))
            end
            new_point[1] = slope * new_point[0] + point[1] - (slope * point[0])
          end

          new_point = new_point.map{ |num| num.round(2) }
          if current != new_point
            new_stroke << new_point

            current = new_point
          end
          last_index += ((index - last_index) / 2).floor
          index = last_index + 1
        end
      end

      new_stroke
    end

    #This methods downsamples a stroke in given interval
    #The number of points in the stroke will be reduced
    def self.downsample stroke, interval=3
      stroke.each_slice(interval).map(&:first)
    end

    #This methods generates a heatmap for the given character pattern
    #A heatmap divides the input character pattern(image of the character) into nxn grids
    #We count the points in each grid and store the number in a map
    #The map array can be used as feature
    #Params:
    #+points+:: flattened strokes i.e. [[x1, y1], [x2, y2]...] because the seperation of points in strokes is irrelevant in this case
    #+grid+:: number of grids
    def self.heatmap points, grid, size

      grid_size = size / grid.to_f

      map = Map.new grid, grid, 0

      #fill the heatmap
      points.each do |point|
        if point[0] < size && point[1] < size
          x_i = (point[0] / grid_size).floor if point[0] < size
          y_i = (point[1] / grid_size).floor if point[1] < size

          map[y_i, x_i] += (1 / points.length.to_f).round(4)
        end
      end

      map
    end
    #This method smooths a heatmap using spatial_weight_filter technique
    #but instead of taking every 2nd grid, it processes every grid and stores the average of the weighted sum of adjacent grids
    #Params:
    #+map+:: a heatmap
    def self.smooth_heatmap map
      grid = map.size
      #map is a heatmap
      new_map = Map.new(grid, grid, 0)

      (0..(grid - 1)).each do |i|
        (0..(grid - 1)).each do |j|
          #weights alternative 
          #        = [1/16, 2/16, 1/16];
          #          [2/16, 4/16, 2/16];
          #          [1/16, 2/16, 1/16]
          #
          #weights = [1/9, 1/9, 1/9];
          #          [1/9, 1/9, 1/9];
          #          [1/9, 1/9, 1/9]
          #
          w11 = (0..(grid-1)).cover?(i+1) && (0..(grid-1)).cover?(j-1)? map[i+1,j-1] * 1 / 9.0 : 0
          w12 = (0..(grid-1)).cover?(i+1) && (0..(grid-1)).cover?(j)? map[i+1,j] * 1 / 9.0 : 0
          w13 = (0..(grid-1)).cover?(i+1) && (0..(grid-1)).cover?(j+1)? map[i+1,j+1] * 1 / 9.0 : 0
          w21 = (0..(grid-1)).cover?(i) && (0..(grid-1)).cover?(j-1)? map[i,j-1] * 1 / 9.0 : 0
          w22 = (0..(grid-1)).cover?(i) && (0..(grid-1)).cover?(j)? map[i,j] * 1 / 9.0 : 0
          w23 = (0..(grid-1)).cover?(i) && (0..(grid-1)).cover?(j+1)? map[i,j+1] * 1 / 9.0 : 0
          w31 = (0..(grid-1)).cover?(i-1) && (0..(grid-1)).cover?(j-1)? map[i-1,j-1] * 1 / 9.0 : 0
          w32 = (0..(grid-1)).cover?(i-1) && (0..(grid-1)).cover?(j)? map[i-1,j] * 1 / 9.0 : 0
          w33 = (0..(grid-1)).cover?(i-1) && (0..(grid-1)).cover?(j+1)? map[i-1,j+1] * 1 / 9.0 : 0

          new_map[i,j] = (w11 + w12 + w13 + w21 + w22 + w23 + w31 + w32 + w33).round(4)
        end
      end

      new_map
    end
  end
end
