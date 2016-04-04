require 'nokogiri'
require 'yaml'
require 'json'
require 'matrix'
#require all files in ./lib/
require File.join(File.dirname(__FILE__), '/kvg_character_recognition/utils.rb')
require File.join(File.dirname(__FILE__), '/kvg_character_recognition/normalization.rb')
require File.join(File.dirname(__FILE__), '/kvg_character_recognition/preprocessor.rb')
require File.join(File.dirname(__FILE__), '/kvg_character_recognition/non_structural_feature.rb')
require File.join(File.dirname(__FILE__), '/kvg_character_recognition/heatmap_feature.rb')
require File.join(File.dirname(__FILE__), '/kvg_character_recognition/kvg_parser.rb')
require File.join(File.dirname(__FILE__), '/kvg_character_recognition/datastore.rb')
require File.join(File.dirname(__FILE__), '/kvg_character_recognition/trainer.rb')
require File.join(File.dirname(__FILE__), '/kvg_character_recognition/template.rb')
require File.join(File.dirname(__FILE__), '/kvg_character_recognition/recognizer.rb')

module KvgCharacterRecognition
  def self.init_datastore filename="characters.json", xml="kanjivg-20150615-2.xml"
    datastore = JSONDatastore.new(filename)
    Template.parse_from_xml xml, datastore
  end
end
