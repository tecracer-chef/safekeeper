lib = File.expand_path("lib/", __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)
require "safekeeper/version"

Gem::Specification.new do |spec|
  spec.name        = "safekeeper"
  spec.version     = Safekeeper::VERSION
  spec.licenses    = ["Nonstandard"]

  spec.summary     = "Interface to talk to different secret managing backends."
  spec.description = "Creates an extensible API to access secrets in a unified fashion."
  spec.authors     = ["tecRacer Opensource"]
  spec.email       = ["opensource@tecracer.de"]
  spec.homepage    = "http://example.com"

  spec.files       = Dir["lib/**/**/**"]
  spec.files      += ["README.md", "CHANGELOG.md"]

  spec.required_ruby_version = ">= 2.6"

  spec.add_dependency "hashie", "~> 4.1"
  spec.add_dependency "vault", "~> 0.15"
  spec.add_dependency "aws-sdk-secretsmanager", "~> 1.45"
end
