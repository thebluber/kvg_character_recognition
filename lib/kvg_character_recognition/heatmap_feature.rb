module KvgCharacterRecognition
  class HeatmapFeature
    include NonStructuralFeature
    attr_accessor :size, :weights, :number_of_grids, :heatmaps
    def initialize bi_normed, ld_normed, pd_normed, size, number_of_grids, weights=[1/9.0, 1/9.0, 1/9.0, 1/9.0, 1/9.0, 1/9.0, 1/9.0, 1/9.0, 1/9.0]
      @size = size
      @number_of_grids = number_of_grids
      @number_of_points = bi_normed.flatten(1).count
      @weights = weights
      @heatmaps = smooth(generate_heatmaps(bi_normed, ld_normed, pd_normed))
    end

    def generate_heatmaps bi_normed, ld_normed, pd_normed

      grid_size = size / @number_of_grids.to_f

      map = Map.new @number_of_grids, @number_of_grids, [0, 0, 0]

      #fill the heatmap
      bi_normed.each do |stroke|
        stroke.each do |point|
          grid1 = [(point[0] / grid_size).floor, (point[1] / grid_size).floor]

          map[grid1[0], grid1[1]] = [map[grid1[0], grid1[1]][0] + (1 / @number_of_points.to_f).round(4),
                                     map[grid1[0], grid1[1]][1],
                                     map[grid1[0], grid1[1]][2]] if grid1[0] < @number_of_grids && grid1[1] < @number_of_grids
        end
      end
      ld_normed.each do |stroke|
        stroke.each do |point|
          grid2 = [(point[0] / grid_size).floor, (point[1] / grid_size).floor]

          map[grid2[0], grid2[1]] = [map[grid2[0], grid2[1]][0],
                                     map[grid2[0], grid2[1]][1] + (1 / @number_of_points.to_f).round(4),
                                     map[grid2[0], grid2[1]][2]] if grid2[0] < @number_of_grids && grid2[1] < @number_of_grids
        end
      end
      pd_normed.each do |stroke|
        stroke.each do |point|
          grid4 = [(point[0] / grid_size).floor, (point[1] / grid_size).floor]

          map[grid4[0], grid4[1]] = [map[grid4[0], grid4[1]][0],
                                     map[grid4[0], grid4[1]][1],
                                     map[grid4[0], grid4[1]][2] + (1 / @number_of_points.to_f).round(4)] if grid4[0] < @number_of_grids && grid4[1] < @number_of_grids
        end
      end
      map
    end
  end
end
