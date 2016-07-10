require 'bundler'

require 'rake/extensiontask'

require 'rake'
require 'rspec/core/rake_task'

desc "Run all examples"
RSpec::Core::RakeTask.new('spec') do |t|
  t.pattern = FileList['spec/**/*_spec.rb']
end

task :default  => :spec

Rake::ExtensionTask.new('mwisd_fp') do |ext|
  ext.lib_dir = 'lib/mwisd_fp'              # put binaries into this folder.
end

Rake::ExtensionTask.new('histogroup') do |ext|
  ext.lib_dir = 'lib/histogroup'              # put binaries into this folder.
end

