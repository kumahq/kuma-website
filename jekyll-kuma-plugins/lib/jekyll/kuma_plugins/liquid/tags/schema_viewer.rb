# frozen_string_literal: true

require 'json'
require 'yaml'
require 'cgi'
require_relative '../../common/path_helpers'

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
            params_list.each do |item|
              sp = item.split('=')
              params[sp[0]] = sp[1] unless sp[1].to_s.empty?
            end
            @load = create_loader(params['type'], name)
          end

          def render(context)
            release = context.registers[:page]['release']
            base_paths = context.registers[:site].config.fetch(PATHS_CONFIG, DEFAULT_PATHS)
            data = @load.call(base_paths, release)
            SchemaRenderer.new(data).render
          rescue StandardError => e
            Jekyll.logger.warn('Failed reading schema_viewer', e)
            "<div class='schema-viewer-error'>Error loading schema: #{CGI.escapeHTML(e.message)}</div>"
          end

          private

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

        # Renders schema data to HTML
        class SchemaRenderer
          DESCRIPTION_TRUNCATE_LENGTH = 100

          def initialize(schema)
            @definitions = schema['definitions'] || {}
            @root_schema = resolve_ref(schema)
          end

          def render
            <<~HTML
              <div class="schema-viewer">
                #{render_properties(@root_schema, 0)}
              </div>
            HTML
          end

          private

          def resolve_ref(schema)
            return schema unless schema.is_a?(Hash) && schema['$ref']

            ref_path = schema['$ref']
            return schema unless ref_path.start_with?('#/definitions/')

            def_name = ref_path.sub('#/definitions/', '')
            @definitions[def_name] || schema
          end

          def render_properties(schema, depth)
            schema = resolve_ref(schema)
            return '' unless schema.is_a?(Hash) && schema['properties'].is_a?(Hash)

            required_fields = schema['required'] || []
            props = schema['properties'].map do |name, prop|
              render_property(name, prop, required_fields.include?(name), depth)
            end
            "<div class=\"schema-viewer__properties\">#{props.join}</div>"
          end

          def render_property(name, prop, required, depth)
            prop = resolve_ref(prop)
            return '' unless prop.is_a?(Hash)

            build_property_html(name, prop, required, depth)
          end

          def build_property_html(name, prop, required, depth)
            has_children = nested_properties?(prop)
            html = [render_node_open(name, prop, required, depth, has_children)]
            html << render_content_section(prop)
            html << render_children_section(prop, depth) if has_children
            html << '</div>'
            html.join
          end

          def render_node_open(name, prop, required, depth, has_children)
            collapsed = depth.positive? ? 'schema-viewer__node--collapsed' : nil
            expandable = has_children ? 'schema-viewer__node--expandable' : nil
            arrow = has_children ? '<span class="schema-viewer__arrow"></span>' : '<span class="schema-viewer__arrow-placeholder"></span>'
            required_badge = required ? '<span class="schema-viewer__required">required</span>' : nil
            header_attrs = build_header_attrs(has_children, depth)

            <<~HTML
              <div class="schema-viewer__node #{collapsed} #{expandable}" data-depth="#{depth}">
                <div class="schema-viewer__header" #{header_attrs}>
                  #{arrow}
                  <span class="schema-viewer__name">#{CGI.escapeHTML(name)}</span>
                  #{render_type_badge(determine_type(prop))}
                  #{required_badge}
                </div>
            HTML
          end

          def build_header_attrs(expandable, depth)
            return unless expandable

            %(tabindex="0" aria-expanded="#{depth.positive? ? 'false' : 'true'}")
          end

          def render_content_section(prop)
            description = clean_description(prop['description'])
            enum_values = extract_enum_values(prop)
            default_value = prop['default']
            return '' unless description || enum_values || default_value

            content = []
            content << render_description(description) if description
            content << render_enum_values(enum_values) if enum_values
            content << render_default_value(default_value) if default_value
            "<div class=\"schema-viewer__content\">#{content.join}</div>"
          end

          def render_children_section(prop, depth)
            "<div class=\"schema-viewer__children\">#{render_nested_content(prop, depth + 1)}</div>"
          end

          def determine_type(prop)
            return 'enum' if prop['enum']

            type = prop['type']
            return type if type && SchemaViewer::TYPE_BADGES.include?(type)
            return 'object' if prop['properties']
            return 'array' if prop['items']

            'any'
          end

          def render_type_badge(type)
            badge_class = SchemaViewer::TYPE_BADGES.include?(type) ? "schema-viewer__type--#{type}" : 'schema-viewer__type--any'
            "<span class=\"schema-viewer__type #{badge_class}\">#{CGI.escapeHTML(type)}</span>"
          end

          def nested_properties?(prop)
            return true if prop['properties']

            prop['items'] && resolve_ref(prop['items'])['properties']
          end

          def render_nested_content(prop, depth)
            return render_properties(prop, depth) if prop['properties']

            render_properties(resolve_ref(prop['items']), depth) if prop['items']
          end

          def clean_description(desc)
            return unless desc

            desc.gsub('+optional', '').tr("\n", ' ').strip
          end

          def extract_enum_values(prop)
            prop['enum']&.select { |v| v.is_a?(String) }
          end

          def render_description(description)
            return '' unless description

            description = description.to_s.force_encoding('UTF-8')
            if description.length > DESCRIPTION_TRUNCATE_LENGTH
              truncated = description[0...DESCRIPTION_TRUNCATE_LENGTH]
              preview = CGI.escapeHTML(truncated)
              <<~HTML
                <div class="schema-viewer__description" data-full-text="#{description}">
                  <span class="schema-viewer__description-text">#{preview}...</span>
                  <button type="button" class="schema-viewer__show-more" aria-expanded="false">show more</button>
                </div>
              HTML
            else
              "<div class=\"schema-viewer__description\"><span class=\"schema-viewer__description-text\">#{CGI.escapeHTML(description)}</span></div>"
            end
          end

          def render_enum_values(values)
            return '' if values.empty?

            "<div class=\"schema-viewer__enum\">Values: #{values.map { |v| "<code>#{CGI.escapeHTML(v)}</code>" }.join(' | ')}</div>"
          end

          def render_default_value(value)
            return '' if value.nil?

            formatted_value = value.is_a?(String) ? "\"#{value}\"" : JSON.generate(value)
            "<div class=\"schema-viewer__default\">Default: <code>#{CGI.escapeHTML(formatted_value)}</code></div>"
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('schema_viewer', Jekyll::KumaPlugins::Liquid::Tags::SchemaViewer)
