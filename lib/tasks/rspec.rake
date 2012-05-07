begin
  require "rspec/core/rake_task"
  
  plugin = "vendor/plugins/han"
  
  namespace :spec do
    desc "Run the HAN spec tests"
    
    RSpec::Core::RakeTask.new(:han) do |spec|
      spec.pattern = "#{plugin}/spec/**/*_spec.rb"
    end
  end

rescue LoadError
end