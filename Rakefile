gem 'rdoc'
require 'rdoc/task'
require 'rake/extensiontask'
require 'rake/testtask'

task :default => [:compile, :test, :rdoc]

GEMSPEC = eval(File.read(File.expand_path("../salsa20.gemspec", __FILE__)))

Rake::ExtensionTask.new('salsa20_ext')

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*test.rb']
  t.verbose = true
end

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.options += GEMSPEC.rdoc_options
  rdoc.template = ENV['TEMPLATE'] if ENV['TEMPLATE']
  rdoc.rdoc_files.include(*GEMSPEC.extra_rdoc_files)
end
