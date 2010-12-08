require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Medusa-Proxy"
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('config/*.rb')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
