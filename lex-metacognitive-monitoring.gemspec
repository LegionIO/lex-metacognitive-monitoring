# frozen_string_literal: true

require_relative 'lib/legion/extensions/metacognitive_monitoring/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-metacognitive-monitoring'
  spec.version       = Legion::Extensions::MetacognitiveMonitoring::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Metacognitive Monitoring'
  spec.description   = 'Real-time monitoring of cognitive processes: feeling of knowing, judgment of learning, ' \
                       'confidence calibration, error detection, and effort tracking for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-metacognitive-monitoring'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-metacognitive-monitoring'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-metacognitive-monitoring'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-metacognitive-monitoring'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-metacognitive-monitoring/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-metacognitive-monitoring.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
end
