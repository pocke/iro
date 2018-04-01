lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "iro/version"

Gem::Specification.new do |spec|
  spec.name          = "iro"
  spec.version       = Iro::VERSION
  spec.authors       = ["Masataka Pocke Kuwabara"]
  spec.email         = ["kuwabara@pocke.me"]

  spec.summary       = %q{A library for syntax highlighter}
  spec.description   = %q{A library for syntax highlighter. It is based Ripper.}
  spec.homepage      = "https://github.com/pocke/iro"
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.3.0'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency 'minitest', '~> 5.11'
  spec.add_development_dependency 'unification_assertion'

  spec.add_development_dependency 'sanitize', '~> 4.6'
end
