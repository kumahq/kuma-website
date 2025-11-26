# frozen_string_literal: true

module Jekyll
  module KumaPlugins
    module Common
      module PathHelpers
        PATHS_CONFIG = 'mesh_raw_generated_paths'
        DEFAULT_PATHS = ['app/assets'].freeze

        def read_file(paths, file_name)
          paths.each do |path|
            file_path = File.join(path, file_name)
            return File.open(file_path) if File.readable? file_path
          end
          raise "couldn't read #{file_name} in any of these paths: #{paths}"
        end
      end
    end
  end
end
