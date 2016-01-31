require 'bundler'
Bundler.require
require 'yaml'
#require all files in ./lib/
Dir[File.join(File.dirname(__FILE__), '/kvg_character_recognition/*.rb')].each {|file| require file }

module KvgCharacterRecognition

  CONFIG = {
    size: 109, #fixed canvas size of kanjivg data
    downsample_interval: 4,
    interpolate_distance: 0.8,
    heatmap_coarse_grid: 17,
    heatmap_granular_grid: 17,
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
end
