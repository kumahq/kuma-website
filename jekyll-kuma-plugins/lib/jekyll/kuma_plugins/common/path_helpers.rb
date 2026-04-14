# frozen_string_literal: true

require 'pathname'

module Jekyll
  module KumaPlugins
    module Common
      # Shared safe path handling for file reads rooted in configured asset directories.
      module PathHelpers
        PATHS_CONFIG = 'mesh_raw_generated_paths'
        DEFAULT_PATHS = ['app/assets'].freeze

        def optional_path_segment(segment)
          value = segment.to_s.strip
          value.empty? ? nil : value
        end

        def build_relative_path(*segments)
          normalized_segments = segments.flatten.compact.map { |segment| sanitize_relative_path(segment) }
          normalized_segments.reject!(&:empty?)
          raise ArgumentError, 'file path must not be empty' if normalized_segments.empty?

          File.join(*normalized_segments)
        end

        def find_file(paths, file_name)
          relative_path = sanitize_relative_path(file_name)

          paths.each do |path|
            root = canonical_path(path)
            file_path = safe_join(root, relative_path)
            next unless File.file?(file_path) && File.readable?(file_path)

            validate_realpath!(file_path, root, relative_path)
            return file_path
          rescue Errno::ENOENT
            next
          end

          raise "couldn't read #{relative_path} in any of these paths: #{paths}"
        end

        def read_file(paths, file_name)
          file = open_validated_file(paths, file_name)
          file.read
        ensure
          file&.close
        end

        def read_file_content(paths, file_name)
          read_file(paths, file_name)
        end

        private

        def sanitize_relative_path(path)
          candidate = path.to_s.strip
          raise ArgumentError, 'file path must not be empty' if candidate.empty?

          pathname = Pathname.new(candidate)
          raise ArgumentError, "absolute paths are not allowed: #{path}" if pathname.absolute?

          segments = pathname.each_filename.to_a
          raise ArgumentError, "path traversal is not allowed: #{path}" if segments.any? { |segment| segment.empty? || %w[. ..].include?(segment) }

          File.join(*segments)
        end

        def safe_join(root, relative_path)
          candidate = File.expand_path(relative_path, root)
          raise ArgumentError, "path traversal is not allowed: #{relative_path}" unless path_within_root?(candidate, root)

          candidate
        end

        def validate_realpath!(path, root, relative_path)
          resolved_candidate = File.realpath(path)
          raise ArgumentError, "path traversal is not allowed: #{relative_path}" unless path_within_root?(resolved_candidate, root)
        end

        def open_validated_file(paths, file_name)
          relative_path = sanitize_relative_path(file_name)
          file = nil

          paths.each do |path|
            root = canonical_path(path)
            file_path = safe_join(root, relative_path)
            next unless File.file?(file_path) && File.readable?(file_path)

            file = File.new(file_path)
            validate_realpath!(file.path, root, relative_path)
            return file
          rescue Errno::ENOENT
            file&.close
            next
          end

          raise "couldn't read #{relative_path} in any of these paths: #{paths}"
        ensure
          file&.close if $ERROR_INFO
        end

        def canonical_path(path)
          canonical_paths.fetch(path.to_s) do
            expanded_path = File.expand_path(path.to_s)
            canonical_paths[path.to_s] = File.exist?(expanded_path) ? File.realpath(expanded_path) : expanded_path
          end
        end

        def path_within_root?(candidate, root)
          candidate == root || candidate.start_with?(root_prefix(root))
        end

        def canonical_paths
          @canonical_paths ||= {}
        end

        def root_prefix(root)
          root.end_with?(File::SEPARATOR) ? root : "#{root}#{File::SEPARATOR}"
        end
      end
    end
  end
end
