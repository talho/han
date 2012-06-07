begin
  require 'cucumber/rake/task'

  namespace :cucumber do
    desc = "HAN plugin, add any cmd args after --"
    Cucumber::Rake::Task.new(:han, desc) do |t|#{:han => 'db:test:prepare'}
      t.cucumber_opts = "RAILS_ENV=cucumber -r features" + 
                        "-r #{File.join(File.dirname(__FILE__), '..', '..')}/spec/factories.rb " +
                        "-r #{File.join(File.dirname(__FILE__), '..', '..')}/features/step_definitions " +
                        "-r #{File.join(File.dirname(__FILE__), '..', '..')}/features/support " +
                        " #{ARGV[1..-1].join(" ") if ARGV[1..-1]}" +
                        # add all HAN features if none are passed in
                        (ARGV.length <= 1 ? "#{File.join(File.dirname(__FILE__), '..', '..')}/features" : "")
    end
  end
rescue LoadError
  # to catch if cucmber is not installed, as in production
end
