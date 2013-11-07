require 'rspec/core/rake_task'

desc "Run both specs for both recipes and roles"
task :spec do
  Rake::Task['spec:recipes'].invoke
end

namespace :spec do
  RSpec::Core::RakeTask.new(:recipes) do |t|
    t.pattern = %w{ site-cookbooks/**/spec/*_spec.rb}
  end
  RSpec::Core::RakeTask.new(:functional) do |t|
    t.pattern = %w{ spec/functional/*_spec.rb}
  end
end  

desc 'Run foodcritic on all cookbooks or supplied path'
task 'foodcritic', 'path' do |t,args|
  options = [
    '-t', '~solo',    # Skip checks for solo compatibility. We're pretty dependent on search.
    '-t', '~readme',  # Don't warn about README issues.
    '-t', '~FC023',
    '-t', '~FC019'
  ]
  sh 'foodcritic', *options, (args[:path] || 'site-cookbooks')
end

task :default => 'foodcritic'

namespace :berks do
  desc 'Install cookbooks using berkshelf'
  task "install" do
    %x{bundle exec berks install --path vendor}
  end
end
