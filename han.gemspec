# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "han/version"

Gem::Specification.new do |s|
  s.name        = "han"
  s.version     = Han::VERSION
  s.authors     = ["TALHO"]
  s.email       = ["developoers@talho.org"]
  s.homepage    = ""
  s.summary     = %q{}
  s.description = %q{}

  s.files         = ['lib/**/*', 'app/**/*', 'config/**/*', 'db/**/*', 'install.rb', 'LICENSE', 'Rakefile', 'README']
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
