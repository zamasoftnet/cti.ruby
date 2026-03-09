Gem::Specification.new do |spec|
  spec.name          = 'copper-cti'
  spec.version       = '2.1.0'
  spec.authors       = ['Zamasoft']
  spec.email         = ['info@zamasoft.jp']
  spec.summary       = 'CTI driver for Copper PDF server'
  spec.description   = 'Ruby driver for connecting to the Copper PDF document conversion server via the CTIP protocol.'
  spec.homepage      = 'https://github.com/zamasoftnet/cti.ruby'
  spec.license       = 'Apache-2.0'

  spec.required_ruby_version = '>= 1.8.7'

  spec.files         = Dir['src/code/**/*.rb']
  spec.require_paths = ['src/code']

  spec.metadata = {
    'source_code_uri' => 'https://github.com/zamasoftnet/cti.ruby',
  }
end
