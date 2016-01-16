require 'matrix'
require 'nokogiri'

module KvgCharacterRecognition
  #This class contains methods for database interactions
  class Database
    def initialize database_uri
      @db = Sequel.connect(database_uri)
      @characters = @db[:characters]
    end

    #This method creates a database table for storing the extracted features of the templates
    #Arrays of points will be serialized and stored as string
    #Following fields are created:
    # - primary_key :id
    # - String :value
    # - Integer :codepoint
    # - String :serialized_strokes i.e. [stroke, x, y]
    # - String :direction_e1
    # - String :direction_e2
    # - String :direction_e3
    # - String :direction_e4
    # - String :heatmap_smoothed
    # - String :heatmap_significant_points
    def setup
      @db.create_table :characters do
        primary_key :id
        String :value
        Integer :codepoint
        Integer :number_of_strokes
        String :serialized_strokes
        String :direction_e1
        String :direction_e2
        String :direction_e3
        String :direction_e4
        String :heatmap_smoothed
        String :heatmap_significant_points
      end
    end

    def characters_in_stroke_range range
      @characters.where(:number_of_strokes => range)
    end

    def store character
      @characters.insert character
    end

    def persist!
      nil
    end

    #Drop created table
    def drop
      @db.drop_table(:characters) if @db.table_exists?(:characters)
    end
  end
end
