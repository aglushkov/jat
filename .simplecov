# frozen_string_literal: true

# CI=true bundle exec rspec

SimpleCov.enable_coverage :branch
SimpleCov.minimum_coverage line: 100, branch: 100
SimpleCov.at_exit { SimplecovResult.new(SimpleCov.result).print_result }

class SimplecovResult
  def initialize(result)
    @result = result
  end

  def print_result
    statistics = result.coverage_statistics
    percent = ((statistics[:line].percent + statistics[:branch].percent) / 2.0).ceil(2)

    uncovered_files.each(&method(:print_uncovered_file)) if percent < 100
    puts "(#{percent}%) covered"
  end

  private

  attr_reader :result

  def print_uncovered_file(file)
    puts "Uncovered file: #{file.filename}:"

    print_missed_lines(file)
    print_missed_branches(file)

    puts
  end

  def print_missed_lines(file)
    file.missed_lines.each { |line| print_missed_line(line) }
  end

  def print_missed_branches(file)
    file.missed_branches.each { |branch| print_missed_branch(file, branch) }
  end

  def print_missed_line(line)
    puts "#{line.line_number}\t#{line.src}"
  end

  def print_missed_branch(file, branch)
    line_number = branch.report_line
    puts "#{line_number}\t#{file.lines[line_number - 1].src.rstrip} # (uncovered branch :#{branch.type})"
  end

  def uncovered_files
    result.files.select do |file|
      (file.covered_percent < 100) || (file.branches_coverage_percent < 100)
    end
  end
end
