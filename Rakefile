#!/usr/bin/env rake
require "bundler"
require "bundler/gem_helper"
require "rake/testtask"
require "chefstyle"
require "rubocop/rake_task"

require "rspec/core/rake_task"
require "bundler/gem_tasks"

Bundler::GemHelper.install_tasks name: "safekeeper"

RuboCop::RakeTask.new(:lint) do |task|
  task.options << "--display-cop-names"
end

# run tests
task default: %i{test}

Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = "test/unit/**/*_test.rb"
  t.warning = false
  t.verbose = true
  t.ruby_opts = ["--dev"] if defined?(JRUBY_VERSION)
end

require "bump/tasks"
%w{set pre file current}.each { |task| Rake::Task["bump:#{task}"].clear }
Bump.changelog = :editor
Bump.tag_by_default = true

namespace :lint do
  desc "Linting for all markdown files"
  task :markdown do
    require "mdl"

    MarkdownLint.run(%w{--verbose README.md CHANGELOG.md})
  end
end
