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
      weights = [1,3,1]
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
    #0.Normalize strokes to the size 109x109 and center the coordinates using bi moment normalization method
    #1.Smooth strokes if set to true
    #2.Interpolate points by given distance, in order to equalize the sample rate of input and template
    #3.Downsample by given interval
    def self.preprocess strokes, interpolate_distance=0.8, downsample_interval=4, smooth=true
      means, diffs = means_and_diffs(strokes)
      #normalize strokes
      strokes = bi_moment_normalize(means, diffs, strokes)

      strokes.map do |stroke|
        stroke = smooth(stroke) if smooth
        interpolated = interpolate(stroke, interpolate_distance)
        downsample(interpolated, downsample_interval)
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

      diffs = points.inject([[], []]){ |acc, point| acc = [acc[0] << point[0] - means[0], acc[1] << point[1] - means[1]] }
      [means, diffs]
    end

    #This methods normalizes the strokes using bi moment
    #Params:
    #+strokes+:: [[[x1, y1], [x2, y2], ...], [[x1, y1], ...]]
    #+means+:: [x_c, y_c]
    #+diffs+:: [d_x, d_y]; d_x = [d1, d2, ...]
    def self.bi_moment_normalize means, diffs, strokes

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
      strokes.each do |stroke|
        new_stroke = []
        stroke.each do |point|
          if point[0] - means[0] >= 0
            new_x = ( CONFIG[:size] * (point[0] - means[0]) / (4 * Math.sqrt(delta.call(diffs[0], :>=))).round(2) ) + CONFIG[:size]/2
          else
            new_x = ( CONFIG[:size] * (point[0] - means[0]) / (4 * Math.sqrt(delta.call(diffs[0], :<))).round(2) ) + CONFIG[:size]/2
          end
          if point[1] - means[1] >= 0
            new_y = ( CONFIG[:size] * (point[1] - means[1]) / (4 * Math.sqrt(delta.call(diffs[1], :>=))).round(2) ) + CONFIG[:size]/2
          else
            new_y = ( CONFIG[:size] * (point[1] - means[1]) / (4 * Math.sqrt(delta.call(diffs[1], :<))).round(2) ) + CONFIG[:size]/2
          end

          if new_x >= 0 && new_x <= CONFIG[:size] && new_y >= 0 && new_y <= CONFIG[:size]
            new_stroke << [new_x.round(3), new_y.round(3)]
          end
        end
        new_strokes << new_stroke unless new_stroke.empty?
      end
      new_strokes
    end

    #This method returns the significant points of a given character
    #Significant points are:
    #- Start and end point of a stroke
    #- Point on curve or edge
    #To determine whether a point is on curve or edge, we take the 2 adjacent points and calculate the angle between the 2 vectors
    #If the angle is smaller than 150 degree, then the point should be on curve or edge
    def self.significant_points strokes
      points = []
      strokes.each_with_index do |stroke, i|
        points << stroke[0]

        #collect edge points
        #determine whether a point is an edge point by the internal angle between vector P_i-1 - P_i and P_i+1 - P_i
        pre = stroke[0]
        (1..(stroke.length - 1)).each do |j|
          current = stroke[j]
          nex = stroke[j+1]
          if nex
            v1 = [pre[0] - current[0], pre[1] - current[1]]
            v2 = [nex[0] - current[0], nex[1] - current[1]]
            det = v1[0] * v2[1] - (v2[0] * v1[1])
            dot = v1[0] * v2[0] + (v2[1] * v1[1])
            angle = Math.atan2(det, dot) / (Math::PI / 180)

            if angle.abs < 150
              #current point is on a curve or an edge
              points << current
            end
          end
          pre = current
        end

        points << stroke[stroke.length - 1]
      end

      points
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
          if point[0] == current[0] # x2 == x1
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
          new_stroke << new_point

          current = new_point
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
  end
end
