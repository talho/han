require 'spec/rake/spectask'

PLUGIN = "vendor/plugins/han"

namespace :spec do
  desc "Run the HAN spec tests"
  Spec::Rake::SpecTask.new(:han) do |t|
    t.spec_files = FileList["#{PLUGIN}/spec/**/*_spec.rb"]
  end
end
