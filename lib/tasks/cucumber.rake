begin
  require 'cucumber/rake/task'

  ENV["RAILS_ENV"] ||= "cucumber"

  namespace :cucumber do
    desc = "HAN plugin, add any cmd args after --"
    Cucumber::Rake::Task.new(:han, desc) do |t| #{:han => 'db:test:prepare'}
      t.cucumber_opts = "-r features " +
                        "-r vendor/plugins/han/spec/factories.rb " +
                        "-r vendor/plugins/han/features/step_definitions " +
                        "-r vendor/plugins/han/features/support " +
                        " #{ARGV[1..-1].join(" ") if ARGV[1..-1]}" +
                        # add all HAN features if none are passed in
                        (ARGV.grep(/^vendor/).empty? ? "vendor/plugins/han/features" : "")
      t.fork = true
      t.profile = 'default'
    end
  end
rescue LoadError
  # to catch if cucmber is not installed, as in production
end
