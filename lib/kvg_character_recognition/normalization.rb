module KvgCharacterRecognition
  # This module contains various normalization methods
  module Normalization
    #This methods normalizes the strokes using bi moment
    #Params:
    #+strokes+:: [[[x1, y1], [x2, y2], ...], [[x1, y1], ...]]
    #+slant_correction+:: boolean whether a slant correction should be performed
    #returns normed_strokes, normed_strokes_with_slant_correction
    def bi_moment_normalize strokes
      means, diffs = means_and_diffs strokes

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
          x = point[0]
          y = point[1]

          if x - means[0] >= 0
            new_x = ( @size * (x - means[0]) / (4 * Math.sqrt(delta.call(diffs[0], :>=))).round(2) ) + @size/2
          else
            new_x = ( @size * (x - means[0]) / (4 * Math.sqrt(delta.call(diffs[0], :<))).round(2) ) + @size/2
          end

          if y - means[1] >= 0
            new_y = ( @size * (y - means[1]) / (4 * Math.sqrt(delta.call(diffs[1], :>=))).round(2) ) + @size/2
          else
            new_y = ( @size * (y - means[1]) / (4 * Math.sqrt(delta.call(diffs[1], :<))).round(2) ) + @size/2
          end

          if new_x >= 0 && new_x <= @size && new_y >= 0 && new_y <= @size
            new_stroke << [new_x.round(3), new_y.round(3)]
          end
        end
        new_strokes << new_stroke unless new_stroke.empty?
      end
      new_strokes
    end

    # line density equalization
    # strokes must be scaled to 109x109
    def line_density_normalize strokes
      hist_x, hist_y = line_density_histogram strokes
      strokes.map do |stroke|
        stroke.map do |point|
          if point[0] < 109 && point[1] < 109
            [@size * hist_x[point[0].floor] / hist_x.last, @size * hist_y[point[1].floor] / hist_y.last]
          else
            point
          end
        end
      end
    end

    # point density normalization
    def point_density_normalize strokes
      points = strokes.flatten(1)
      h_x, h_y = accumulated_histogram strokes
      strokes.map do |stroke|
        stroke.map do |point|
          [(@size * h_x[point[0].round] / points.length.to_f).round(2), (@size * h_y[point[1].round] / points.length.to_f).round(2)]
        end
      end
    end

    private
    # bitmap for calculating background runlength in line density normalization
    # bitmap_x[i] is a row of position y = i and contains x-values of existing points
    # bitmap_y[i] is a column of position x = i and contains y-values of existing points
    def runlength_bitmap strokes
      bitmap_x = Array.new(@size, [])
      bitmap_y = Array.new(@size, [])

      strokes.each do |stroke|
        stroke.each do |point|
          x = point[0].floor
          y = point[1].floor
          if x < @size && y < @size
            bitmap_x[y] = bitmap_x[y] + [x]
            bitmap_y[x] = bitmap_y[x] + [y]
          end
        end
      end
      [bitmap_x, bitmap_y]
    end

    def runlength row, i
      left = 0
      right = 109

      row.each do |j|
        left = j if j < i && j > left
        right = j if j > i && j < right
      end
      (right - left).to_f
    end

    def line_density_histogram strokes
      bitmap_x, bitmap_y = runlength_bitmap strokes
      acc_x = 0
      acc_y = 0
      hist_x = []
      hist_y = []
      (0..(@size - 1)).each do |i|
        sum_x = 0
        sum_y = 0
        (0..(@size - 1)).each do |j|

          if bitmap_x[j].include? i
            # x = i is in pattern area
            sum_x += 0
          else
            sum_x += 1 / runlength(bitmap_x[j], i)
          end

          if bitmap_y[j].include? i
            # y = i is in pattern area
            sum_y += 0
          else
            sum_y += 1 / runlength(bitmap_y[j], i)
          end
        end

        acc_x += sum_x
        acc_y += sum_y
        hist_x << acc_x
        hist_y << acc_y
      end
      [hist_x, hist_y]
    end


    # accumulated histogram needed by point density normalization
    def accumulated_histogram strokes
      points = strokes.flatten(1)
      grids = @size + 1
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


    #This method calculates means and diffs of x and y coordinates in the strokes
    #The return values are used in the normalization step
    #means, diffs = means_and_diffs strokes
    #Return values:
    #+means+:: [mean_of_x, mean_of_y]
    #+diffs+:: differences of the x and y coordinates to their means i.e. [[d_x1, d_x2 ...], [d_y1, d_y2 ...]]
    def means_and_diffs strokes
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

  end
end
