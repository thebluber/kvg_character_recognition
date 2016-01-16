require 'json'

module KvgCharacterRecognition
  class JSONDatastore
    def initialize filename = 'characters.json'
      @data = load_file(filename)
      @filename = filename
    end

    def load_file filename
      begin
        JSON.parse(File.read(filename), symbolize_names: true)
      rescue
        puts "WARNING: Can't load file, returning empty character collection."
        []
      end
    end

    def characters_in_stroke_range range
      @data.select { |character| range === character[:number_of_strokes] }
    end

    def store character
      @data.push character
    end

    def persist!
      dump @filename
    end

    def dump filename
      File.write(filename, @data.to_json)
    end
  end
end
