# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stack_car/version'

Gem::Specification.new do |spec|
  spec.name          = "stack_car"
  spec.version       = StackCar::VERSION
  spec.authors       = ["Rob Kaufman"]
  spec.email         = ["rob@notch8.com"]

  spec.summary       = %q{A tool to make rails + docker easy}
  spec.homepage      = "https://gitlab.com/notch8/stack_car"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "yard-thor"
  spec.add_development_dependency "pry"
  spec.add_runtime_dependency "dotenv", "~> 2.0"
  spec.add_runtime_dependency "thor", "~> 0.19"
end
