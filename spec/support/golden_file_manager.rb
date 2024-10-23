# spec/support/golden_file_manager.rb
module GoldenFileManager
  def self.load_input(file_path)
    File.read(file_path)
  end

  def self.load_golden(file_path)
    File.read(file_path)
  end

  def self.update_golden(file_path, content)
    File.write(file_path, content)
  end

  def self.assert_output(output, golden_path)
    if File.exist?(golden_path)
      golden_content = load_golden(golden_path)
      if output.strip != golden_content.strip
        if ENV['UPDATE_GOLDEN_FILES'] == 'true'
          update_golden(golden_path, output)
          puts "Golden file updated: #{golden_path}"
        else
          raise "Output does not match golden file #{golden_path}."
        end
      end
    else
      update_golden(golden_path, output)
      puts "Golden file created: #{golden_path}"
    end
  end
end
