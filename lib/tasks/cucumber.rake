begin
  require 'cucumber/rake/task'

  namespace :cucumber do
    desc = "HAN plugin, add any cmd args after --"
    Cucumber::Rake::Task.new(:han, desc) do |t|#{:han => 'db:test:prepare'}
      t.cucumber_opts = "-r vendor/extentions/han/spec/factories.rb " +
                        "-r vendor/extentions/han/features/step_definitions " +
                        "-r vendor/extentions/han/features/support " +
                        " #{ARGV[1..-1].join(" ") if ARGV[1..-1]}" +
                        # add all HAN features if none are passed in
                        (ARGV.grep(/^vendor/).empty? ? "vendor/extentions/han/features" : "")
    end
  end
rescue LoadError
  # to catch if cucmber is not installed, as in production
end
