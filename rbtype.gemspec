$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rbtype/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rbtype"
  s.version     = Rbtype::VERSION
  s.authors     = ["Francois Chagnon"]
  s.email       = ["francois.chagnon@shopify.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Rbtype."
  s.description = "TODO: Description of Rbtype."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.1.4"

  s.add_development_dependency "sqlite3"
end
