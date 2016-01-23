# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kvg_character_recognition/version'

Gem::Specification.new do |spec|
  spec.name          = "kvg_character_recognition"
  spec.version       = KvgCharacterRecognition::VERSION
  spec.authors       = ["Jiayi Zheng"]
  spec.email         = ["thebluber@gmail.com"]

  spec.summary       = "CJK-character recognition using template matching techniques and template data from KanjiVG project"
  spec.description   = %q{This gem contains a CJK-character recognition engine using pattern/template matching techniques.
  It can recognize stroke-order and stroke-number free handwritten character patterns in the format [stroke1, stroke2 ...].
  A stroke is an array of points in the format [[x1, y1], [x2, y2], ...].
  KanjiVG data(characters in svg format) from https://github.com/KanjiVG/kanjivg/releases are used as templates.
  }
  spec.homepage      = "https://github.com/thebluber/kvg_character_recognition"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f == 'kvg_character_recognition-0.1.2.gem' || f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri"
  spec.add_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
