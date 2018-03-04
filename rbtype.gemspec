$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rbtype/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rbtype"
  s.version     = Rbtype::VERSION
  s.authors     = ["Francois Chagnon"]
  s.email       = ["francois.chagnon@shopify.com"]
  s.homepage    = "https://github.com/EiNSTeiN-/rbtype"
  s.summary     = "ruby type inference"
  s.description = "ruby type inference"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib,exe}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.bindir = 'exe'
  s.executables = s.files.grep(%r{^exe/}) { |f| File.basename(f) }

  s.add_dependency "activesupport"
  s.add_dependency "parser"
  s.add_dependency "colorize"
  s.add_dependency "bundler"

  s.add_development_dependency "rspec"
end
