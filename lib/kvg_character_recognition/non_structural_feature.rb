module KvgCharacterRecognition
  module NonStructuralFeature
    #This class can be used for storing heatmap count and directional feature densities
    #basically it is a nxm matrix with an initial value in each cell
    class Map
      attr_accessor :initial_value
      #Make a new map with
      #Params:
      #+n+:: row length
      #+m+:: column length
      #+initial_value+:: for heatmap initial_value = 0 and for directional feature densities initial_value = [0, 0, 0, 0] <= [weight in e1, weight in e2, ...]
      def initialize n, m, initial_value
        @array = Array.new(n * m, initial_value)
        @n = n
        @m = m
        @initial_value = initial_value
      end

      #Access value in the cell of i-th row and j-th column
      #e.g. map[i,j]
      def [](i, j)
        @array[j*@n + i]
      end

      #Store value in the cell of i-th row and j-th column
      #e.g. map[i,j] = value
      def []=(i, j, value)
        @array[j*@n + i] = value
      end

      def to_a
        @array
      end

      #Normaly n is the same as m
      def size
        @n
      end
    end

    def smooth map
      new_map = Map.new(@number_of_grids, @number_of_grids, map.initial_value)

      (0..(@number_of_grids - 1)).each do |i|
        (0..(@number_of_grids - 1)).each do |j|
          #weights alternative 
          #        = [1/16, 2/16, 1/16];
          #          [2/16, 4/16, 2/16];
          #          [1/16, 2/16, 1/16]
          #
          #weights = [1/9, 1/9, 1/9];
          #          [1/9, 1/9, 1/9];
          #          [1/9, 1/9, 1/9]
          #
          w11 = (0..(@number_of_grids-1)).cover?(i+1) && (0..(@number_of_grids-1)).cover?(j-1)? map[i+1,j-1].map{|e| e * @weights[0]} : [0, 0, 0]
          w12 = (0..(@number_of_grids-1)).cover?(i+1) && (0..(@number_of_grids-1)).cover?(j)? map[i+1,j].map{|e| e * @weights[1]} : [0, 0, 0]
          w13 = (0..(@number_of_grids-1)).cover?(i+1) && (0..(@number_of_grids-1)).cover?(j+1)? map[i+1,j+1].map{|e| e * @weights[2]} : [0, 0, 0]
          w21 = (0..(@number_of_grids-1)).cover?(i) && (0..(@number_of_grids-1)).cover?(j-1)? map[i,j-1].map{|e| e * @weights[3]} : [0, 0, 0]
          w22 = (0..(@number_of_grids-1)).cover?(i) && (0..(@number_of_grids-1)).cover?(j)? map[i,j].map{|e| e * @weights[4]} : [0, 0, 0]
          w23 = (0..(@number_of_grids-1)).cover?(i) && (0..(@number_of_grids-1)).cover?(j+1)? map[i,j+1].map{|e| e * @weights[5]} : [0, 0, 0]
          w31 = (0..(@number_of_grids-1)).cover?(i-1) && (0..(@number_of_grids-1)).cover?(j-1)? map[i-1,j-1].map{|e| e * @weights[6]} : [0, 0, 0]
          w32 = (0..(@number_of_grids-1)).cover?(i-1) && (0..(@number_of_grids-1)).cover?(j)? map[i-1,j].map{|e| e * @weights[7]} : [0, 0, 0]
          w33 = (0..(@number_of_grids-1)).cover?(i-1) && (0..(@number_of_grids-1)).cover?(j+1)? map[i-1,j+1].map{|e| e * @weights[8]} : [0, 0, 0]

          new_map[i,j] = [(w11[0] + w12[0] + w13[0] + w21[0] + w22[0] + w23[0] + w31[0] + w32[0] + w33[0]).round(3),
                          (w11[1] + w12[1] + w13[1] + w21[1] + w22[1] + w23[1] + w31[1] + w32[1] + w33[1]).round(3),
                          (w11[2] + w12[2] + w13[2] + w21[2] + w22[2] + w23[2] + w31[2] + w32[2] + w33[2]).round(3)]
        end
      end

      new_map
    end
  end
end
