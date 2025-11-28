# frozen_string_literal: true

require 'json'
require 'yaml'
require 'cgi'
require_relative '../../common/path_helpers'
require_relative 'schema_viewer/renderer'

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        # Renders JSON schema as interactive HTML viewer
        class SchemaViewer < ::Liquid::Tag
          include Jekyll::KumaPlugins::Common::PathHelpers

          TYPE_BADGES = %w[string boolean integer number object array enum].freeze

          def initialize(tag_name, markup, options)
            super
            name, *params_list = @markup.split
            params = { 'type' => 'policy' }
            @filters = {}

            parse_parameters(params_list, params)
            @load = create_loader(params['type'], name)
          end

          def render(context)
            release = context.registers[:page]['release']
            base_paths = context.registers[:site].config.fetch(PATHS_CONFIG, DEFAULT_PATHS)
            data = @load.call(base_paths, release)
            SchemaViewerComponents::Renderer.new(data, @filters).render
          rescue StandardError => e
            Jekyll.logger.warn('Failed reading schema_viewer', e)
            "<div class='schema-viewer-error'>Error loading schema: #{CGI.escapeHTML(e.message)}</div>"
          end

          private

          def parse_parameters(params_list, params)
            params_list.each do |item|
              sp = item.split('=', 2)
              key = sp[0]
              value = sp[1]
              next if value.to_s.empty?

              # If key contains a dot, it's a filter path (e.g., targetRef.kind)
              if key.include?('.')
                # Split comma-separated values
                @filters[key] = value.split(',').map(&:strip)
              else
                params[key] = value
              end
            end
          end

          def create_loader(type, name)
            case type
            when 'proto' then proto_loader(name)
            when 'crd' then crd_loader(name)
            when 'policy' then policy_loader(name)
            else
              raise "Invalid type: #{type}"
            end
          end

          def proto_loader(name)
            lambda do |paths, release|
              JSON.parse(read_file(paths, File.join(release.to_s, 'raw', 'protos', "#{name}.json")).read)
            end
          end

          def crd_loader(name)
            lambda do |paths, release|
              d = YAML.safe_load(read_file(paths, File.join(release.to_s, 'raw', 'crds', "#{name}.yaml")).read)
              d['spec']['versions'][0]['schema']['openAPIV3Schema']
            end
          end

          def policy_loader(name)
            lambda do |paths, release|
              d = YAML.safe_load(read_file(paths, File.join(release.to_s, 'raw', 'crds', "kuma.io_#{name.downcase}.yaml")).read)
              d['spec']['versions'][0]['schema']['openAPIV3Schema']['properties']['spec']
            end
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('schema_viewer', Jekyll::KumaPlugins::Liquid::Tags::SchemaViewer)
