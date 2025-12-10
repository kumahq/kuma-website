# frozen_string_literal: true

require 'fileutils'
require 'diff/lcs'

module GoldenFileManager
  ASSETS_DIR = 'dist/vite/assets/'
  OUTPUT_CSS = File.join(ASSETS_DIR, 'application.css')
  OUTPUT_JS = File.join(ASSETS_DIR, 'application.js')

  def self.load_input(file_path)
    File.read(file_path)
  end

  def self.load_golden(file_path)
    File.read(file_path)
  end

  def self.update_golden(file_path, content)
    File.write(file_path, content)
  end

  def self.remove_dynamic_attributes(html)
    # Remove all occurrences of data-tab attributes
    html.gsub(/ data-tab="[^"]*"/, '')
  end

  def self.find_latest_assets
    latest_css = Dir.glob("#{ASSETS_DIR}*.css").max_by { |f| File.mtime(f) }
    latest_js = Dir.glob("#{ASSETS_DIR}*.js").max_by { |f| File.mtime(f) }

    [latest_css, latest_js]
  end

  def self.copy_file_if_different(src, dest)
    return unless src && !File.identical?(src, dest)

    FileUtils.cp(src, dest)
  end

  def self.copy_latest_assets
    css_file, js_file = find_latest_assets

    FileUtils.mkdir_p(ASSETS_DIR)
    copy_file_if_different(css_file, OUTPUT_CSS) if css_file
    copy_file_if_different(js_file, OUTPUT_JS) if js_file
  end

  def self.build_header
    <<~HTML
      <link rel="stylesheet" href="http://localhost:8000/#{OUTPUT_CSS}" />
      <script src="http://localhost:8000/#{OUTPUT_JS}" crossorigin="anonymous" type="module"></script>
    HTML
  end

  def self.assert_output(output, golden_path, include_header: false)
    # Remove dynamic attributes from the actual output
    cleaned_output = remove_dynamic_attributes(output)

    # Add header if needed
    if include_header
      copy_latest_assets
      header = build_header
      cleaned_output = "#{header}\n\n#{cleaned_output}"
    end

    # Load the golden file content (original)
    if File.exist?(golden_path)
      golden_content = load_golden(golden_path)
    else
      # If the golden file does not exist, create it
      update_golden(golden_path, cleaned_output.strip)
      puts "Golden file created: #{golden_path}"
      return
    end

    # Trim insignificant whitespace for comparison (removing indentation and trailing spaces)
    trimmed_output = trim_insignificant_whitespace(cleaned_output)
    trimmed_golden_content = trim_insignificant_whitespace(golden_content)

    # Compare the trimmed versions
    return unless trimmed_output != trimmed_golden_content

    if ENV['UPDATE_GOLDEN_FILES'] == 'true'
      # Update golden file if necessary
      update_golden(golden_path, cleaned_output)
      puts "Golden file updated: #{golden_path}"
    else
      # Print the diff of original (untrimmed) content for better visibility
      puts "Output does not match golden file at #{golden_path}."
      print_diff(golden_content, cleaned_output) # use original content for diff
      raise "Output does not match golden file at #{golden_path}."
    end
  end

  # Trim insignificant whitespace: leading/trailing spaces and indentation
  def self.trim_insignificant_whitespace(content)
    # Split content into lines, remove leading spaces and trailing whitespace
    content.force_encoding('UTF-8').lines.map(&:rstrip).reject(&:empty?).join("\n")
  end

  def self.print_diff(expected, actual, context_lines: 5)
    expected_lines = expected.split("\n")
    actual_lines = actual.split("\n")

    diffs = Diff::LCS.sdiff(expected_lines, actual_lines)

    # Collect all the indexes of differences
    diff_indexes = diffs.each_index.reject { |i| diffs[i].action == '=' }

    # If there are no differences, return
    return if diff_indexes.empty?

    # Get the range of lines to display (5 lines before and after the first and last diffs)
    first_diff = diff_indexes.first
    last_diff = diff_indexes.last
    start_line = [first_diff - context_lines, 0].max
    end_line = [last_diff + context_lines, diffs.size - 1].min

    puts "\nDiff (showing #{context_lines} lines before and after changes):\n\n"

    (start_line..end_line).each do |i|
      diff = diffs[i]

      case diff.action
      when '='
        puts " #{i + 1}: #{diff.old_element}"  # Unchanged line
      when '-'
        puts "-#{i + 1}: #{diff.old_element}"  # Line in golden file but missing in actual output
      when '+'
        puts "+#{i + 1}: #{diff.new_element}"  # Line in actual output but missing in golden file
      when '!'
        puts "-#{i + 1}: #{diff.old_element}"  # Modified line in golden file
        puts "+#{i + 1}: #{diff.new_element}"  # Modified line in actual output
      end
    end

    puts "\n"
  end
end
