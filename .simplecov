# frozen_string_literal: true

SimpleCov.command_name "Unit Tests"
SimpleCov.formatter SimpleCov::Formatter::SimpleFormatter if ENV["CI"]
SimpleCov.enable_coverage :branch
SimpleCov.minimum_coverage line: 100, branch: 100

SimpleCov.at_exit do
  if ENV["CI"]
    stats = SimpleCov.result.coverage_statistics
    puts "(#{stats[:line].percent.floor(2)}%) covered"
    puts "(#{stats[:branch].percent.floor(2)}%) branch coverage"
  else
    SimpleCov.result.format! # Default behavior
  end
end
