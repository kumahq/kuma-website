# spec/support/golden_file_manager.rb
require 'fileutils'

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

  def self.copy_latest_assets
    css_file, js_file = find_latest_assets

    # Ensure the output directory exists
    FileUtils.mkdir_p(ASSETS_DIR)

    # Copy the latest CSS and JS files to application.css and application.js in the dist/vite/assets directory
    FileUtils.cp(css_file, OUTPUT_CSS)
    FileUtils.cp(js_file, OUTPUT_JS)
  end

  def self.build_header
    # After copying, use the fixed file names for the header
    <<~HTML
      <link rel="stylesheet" href="http://localhost:8000/#{OUTPUT_CSS}" />
      <script src="http://localhost:8000/#{OUTPUT_JS}" crossorigin="anonymous" type="module"></script>
    HTML
  end

  def self.assert_output(output, golden_path, include_header: false)
    # Clean up output to remove dynamic attributes
    cleaned_output = remove_dynamic_attributes(output).strip

    # Add header if requested
    if include_header
      copy_latest_assets  # Ensure the latest assets are copied to the fixed filenames
      header = build_header
      cleaned_output = "#{header}\n\n#{cleaned_output}"
    end

    if File.exist?(golden_path)
      golden_content = load_golden(golden_path).strip
      if cleaned_output != golden_content
        if ENV['UPDATE_GOLDEN_FILES'] == 'true'
          update_golden(golden_path, cleaned_output)
          puts "Golden file updated: #{golden_path}"
        else
          raise "Output does not match golden file #{golden_path}."
        end
      end
    else
      update_golden(golden_path, cleaned_output)
      puts "Golden file created: #{golden_path}"
    end
  end
end
