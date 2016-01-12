require 'bundler'
Bundler.require
require 'yaml'
#require all files in ./lib/
Dir[File.join(File.dirname(__FILE__), '/kvg_character_recognition/*.rb')].each {|file| require file }

module KvgCharacterRecognition

  @db = Sequel.connect('sqlite://characters.db'),
  CONFIG = {
    size: 109, #fixed canvas size of kanjivg data
    downsample_interval: 4,
    interpolate_distance: 0.8,
    direction_grid: 15,
    smoothed_heatmap_grid: 20,
    significant_points_heatmap_grid: 3
  }
  VALID_KEYS = CONFIG.keys

  #Configure through hash
  def self.configure(opts = {})
    opts.each {|k,v| CONFIG[k.to_sym] = v if VALID_KEYS.include? k.to_sym}
  end

  #Configure with yaml
  def self.configure_with(yml)
    begin
      config = YAML::load(IO.read(yml))
    rescue Errno::ENOENT
      log(:warning, "YAML configuration file couldn't be found. Using defaults."); return
    rescue Psych::SyntaxError
      log(:warning, "YAML configuration file contains invalid syntax. Using defaults."); return
    end

    configure(config)
  end

  #Configure database
  def self.configure_database(yml)
    begin
      db_config = YAML::load(IO.read(yml))
    rescue Errno::ENOENT
      log(:warning, "YAML configuration file couldn't be found. Using defaults."); return
    rescue Psych::SyntaxError
      log(:warning, "YAML configuration file contains invalid syntax. Using defaults."); return
    end
    @db = Sequel.connect(yml)
  end

  #getter
  def self.db
    @db
  end

end
