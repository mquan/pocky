# frozen_string_literal: true

require_relative "lib/pocky/version"

Gem::Specification.new do |spec|
  spec.name          = "pocky"
  spec.version       = Pocky::VERSION
  spec.authors       = ["Quan Nguyen"]
  spec.email         = ["mquannie@gmail.com"]

  spec.summary       = "A ruby gem that generates dependency graph for your packwerk packages"
  spec.description   = "A ruby gem that generates dependency graph for your packwerk packages"
  spec.homepage      = "https://github.com/mquan/pocky"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mquan/pocky"
  spec.metadata["changelog_uri"] = "https://github.com/mquan/pocky"

  spec.files = Dir.chdir(__dir__) do
    %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test|spec|features|static)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = %w(lib)

  spec.add_dependency "ruby-graphviz", "~> 1"
end
