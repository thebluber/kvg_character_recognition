require 'matrix'
module KvgCharacterRecognition
  #This class contains a collection of methods for extracting useful features
  class FeatureExtractor

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

          map[y_i, x_i] = map[y_i, x_i] + 1
        end
      end

      map
    end

    #This method calculates the directional feature densities and stores them in a map
    #The process and algorithm is described in the paper "On-line Recognition of Freely Handwritten Japanese Characters Using Directional Feature Densities" by Akinori Kawamura and co.
    #Params:
    #+strokes+:: [[[x1, y1], [x2, y2] ...], [[x1, y1], ...]]]
    #+grid+:: number of grids in which the input character pattern should be seperated. Default is 15 as in the paper
    def self.directional_feature_densities strokes, grid
      #initialize a map for storing the weights in each directional space
      map = Map.new grid, grid, [0, 0, 0, 0]

      #step width
      step = CONFIG[:size] / grid.to_f

      strokes.each do |stroke|
        current_p = stroke[0]
        stroke.each do |point|
          next if point == current_p
          #map current point coordinate to map index
          #i_x = xth column
          #i_y = yth row
          i_x = (current_p[0] / step).floor
          i_y = (current_p[1] / step).floor

          #direction vector V_ij = P_ij+1 - P_ij
          v = [point[0] - current_p[0], point[1] - current_p[1]]
          #store the sum of decomposed direction vectors in the corresponding grid
          decomposed = decompose(v)
          map[i_y, i_x] = [map[i_y, i_x][0] + decomposed[0],
                           map[i_y, i_x][1] + decomposed[1],
                           map[i_y, i_x][2] + decomposed[2],
                           map[i_y, i_x][3] + decomposed[3]]
        end
      end
      map
    end

    #This method is a helper method for calculating directional feature density
    #which decomposes the direction vector into predefined direction spaces
    #- e1: [1, 0]
    #- e2: [1/sqrt(2), 1/sqrt(2)]
    #- e3: [0, 1]
    #- e4: [-1/sqrt(2), 1/sqrt(2)]
    #Params:
    #+v+:: direction vector of 2 adjacent points V_ij = P_ij+1 - P_ij
    def self.decompose v
      e1 = [1, 0]
      e2 = [1/Math.sqrt(2), 1/Math.sqrt(2)]
      e3 = [0, 1]
      e4 = [-1/Math.sqrt(2), 1/Math.sqrt(2)]
      #angle between vector v and e1
      #det = x1*y2 - x2*y1
      #dot = x1*x2 + y1*y2
      #atan2(det, dot) in range 0..180 and 0..-180
      angle = (Math.atan2(v[1], v[0]) / (Math::PI / 180)).floor
      if (0..44).cover?(angle) || (-180..-136).cover?(angle)
        decomposed = [(Matrix.columns([e1, e2]).inverse * Vector.elements(v)).to_a, 0, 0].flatten
      elsif (45..89).cover?(angle) || (-135..-91).cover?(angle)
        decomposed = [0, (Matrix.columns([e2, e3]).inverse * Vector.elements(v)).to_a, 0].flatten
      elsif (90..134).cover?(angle) || (-90..-44).cover?(angle)
        decomposed = [0, 0, (Matrix.columns([e3, e4]).inverse * Vector.elements(v)).to_a].flatten
      elsif (135..179).cover?(angle) || (-45..-1).cover?(angle)
        tmp = (Matrix.columns([e4, e1]).inverse * Vector.elements(v)).to_a
        decomposed = [tmp[0], 0, 0, tmp[1]]
      end

      decomposed
    end

    #This methods reduces the dimension of directonal feature densities stored in the map
    #It takes every 2nd grid of directional_feature_densities map and stores the average of the weighted sum of adjacent grids around it
    #weights = [1/16, 2/16, 1/16];
    #          [2/16, 4/16, 2/16];
    #          [1/16, 2/16, 1/16]
    #Params:
    #+map+:: directional feature densities map i.e. [[e1, e2, e3, e4], [e1, e2, e3, e4] ...] for each grid of input character pattern
    def self.spatial_weight_filter map
      #default grid should be 15
      grid = map.size
      new_grid = (map.size / 2.0).ceil
      new_map = Map.new(new_grid, new_grid, [0, 0, 0, 0])

      (0..(grid - 1)).each_slice(2) do |i, i2|
        (0..(grid - 1)).each_slice(2) do |j, j2|
          #weights = [1/16, 2/16, 1/16];
          #          [2/16, 4/16, 2/16];
          #          [1/16, 2/16, 1/16]
          w11 = (0..(grid-1)).cover?(i+1) && (0..(grid-1)).cover?(j-1)? map[i+1,j-1].map{|e| e * 1 / 16.0} : [0, 0, 0, 0]
          w12 = (0..(grid-1)).cover?(i+1) && (0..(grid-1)).cover?(j)? map[i+1,j].map{|e| e * 2 / 16.0} : [0, 0, 0, 0]
          w13 = (0..(grid-1)).cover?(i+1) && (0..(grid-1)).cover?(j+1)? map[i+1,j+1].map{|e| e * 1 / 16.0} : [0, 0, 0, 0]
          w21 = (0..(grid-1)).cover?(i) && (0..(grid-1)).cover?(j-1)? map[i,j-1].map{|e| e * 2 / 16.0} : [0, 0, 0, 0]
          w22 = (0..(grid-1)).cover?(i) && (0..(grid-1)).cover?(j)? map[i,j].map{|e| e * 4 / 16.0} : [0, 0, 0, 0]
          w23 = (0..(grid-1)).cover?(i) && (0..(grid-1)).cover?(j+1)? map[i,j+1].map{|e| e * 2 / 16.0} : [0, 0, 0, 0]
          w31 = (0..(grid-1)).cover?(i-1) && (0..(grid-1)).cover?(j-1)? map[i-1,j-1].map{|e| e * 1 / 16.0} : [0, 0, 0, 0]
          w32 = (0..(grid-1)).cover?(i-1) && (0..(grid-1)).cover?(j)? map[i-1,j].map{|e| e * 2 / 16.0} : [0, 0, 0, 0]
          w33 = (0..(grid-1)).cover?(i-1) && (0..(grid-1)).cover?(j+1)? map[i-1,j+1].map{|e| e * 1 / 16.0} : [0, 0, 0, 0]

          new_map[i/2,j/2] = [w11[0] + w12[0] + w13[0] + w21[0] + w22[0] + w23[0] + w31[0] + w32[0] + w33[0],
                              w11[1] + w12[1] + w13[1] + w21[1] + w22[1] + w23[1] + w31[1] + w32[1] + w33[1],
                              w11[2] + w12[2] + w13[2] + w21[2] + w22[2] + w23[2] + w31[2] + w32[2] + w33[2],
                              w11[3] + w12[3] + w13[3] + w21[3] + w22[3] + w23[3] + w31[3] + w32[3] + w33[3]]
        end
      end

      new_map
    end

    #This method smooths a heatmap using spatial_weight_filter technique
    #but instead of taking every 2nd grid, it processes every grid and stores the average of the weighted sum of adjacent grids
    #Params:
    #+map+:: a heatmap
    def self.smooth_heatmap map
      #map is a heatmap
      new_map = Map.new(map.size, map.size, 0)

      (0..(grid - 1)).each do |i|
        (0..(grid - 1)).each do |j|
          #weights = [1/16, 2/16, 1/16];
          #          [2/16, 4/16, 2/16];
          #          [1/16, 2/16, 1/16]
          w11 = (0..(grid-1)).cover?(i+1) && (0..(grid-1)).cover?(j-1)? map[i+1,j-1] * 1 / 16.0 : 0
          w12 = (0..(grid-1)).cover?(i+1) && (0..(grid-1)).cover?(j)? map[i+1,j] * 2 / 16.0 : 0
          w13 = (0..(grid-1)).cover?(i+1) && (0..(grid-1)).cover?(j+1)? map[i+1,j+1] * 1 / 16.0 : 0
          w21 = (0..(grid-1)).cover?(i) && (0..(grid-1)).cover?(j-1)? map[i,j-1] * 2 / 16.0 : 0
          w22 = (0..(grid-1)).cover?(i) && (0..(grid-1)).cover?(j)? map[i,j] * 4 / 16.0 : 0
          w23 = (0..(grid-1)).cover?(i) && (0..(grid-1)).cover?(j+1)? map[i,j+1] * 2 / 16.0 : 0
          w31 = (0..(grid-1)).cover?(i-1) && (0..(grid-1)).cover?(j-1)? map[i-1,j-1] * 1 / 16.0 : 0
          w32 = (0..(grid-1)).cover?(i-1) && (0..(grid-1)).cover?(j)? map[i-1,j] * 2 / 16.0 : 0
          w33 = (0..(grid-1)).cover?(i-1) && (0..(grid-1)).cover?(j+1)? map[i-1,j+1] * 1 / 16.0 : 0

          new_map[i,j] = w11 + w12 + w13 + w21 + w22 + w23 + w31 + w32 + w33
        end
      end

      new_map
    end
  end
end
