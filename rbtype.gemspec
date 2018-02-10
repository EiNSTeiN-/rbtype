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

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "activesupport", "~> 5.1.4"
  s.add_dependency "parser"

  s.add_development_dependency "rspec"
end
