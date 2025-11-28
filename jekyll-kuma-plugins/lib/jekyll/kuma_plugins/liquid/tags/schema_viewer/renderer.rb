# frozen_string_literal: true

require 'json'
require 'cgi'

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        module SchemaViewerComponents
          # Renders schema data to HTML
          class Renderer
            DESCRIPTION_TRUNCATE_LENGTH = 100

            def initialize(schema, filters = {})
              @definitions = schema['definitions'] || {}
              @root_schema = resolve_ref(schema)
              @filters = filters
            end

            def render
              filtered_schema = apply_filters(@root_schema, [])
              <<~HTML
                <div class="schema-viewer">
                  #{render_properties(filtered_schema, 0, [])}
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

            def extract_ref_name(schema)
              return unless schema.is_a?(Hash) && schema['$ref']

              ref_path = schema['$ref']
              return unless ref_path.start_with?('#/definitions/')

              def_name = ref_path.sub('#/definitions/', '')
              # Simplify long definition names (e.g., "kuma.mesh.v1alpha1.Type" -> "Type")
              def_name.split('.').last
            end

            def render_properties(schema, depth, path)
              schema = resolve_ref(schema)
              return '' unless schema.is_a?(Hash) && schema['properties'].is_a?(Hash)

              required_fields = schema['required'] || []
              props = schema['properties'].map do |name, prop|
                render_property(name, prop, required_fields.include?(name), depth, path)
              end
              "<div class=\"schema-viewer__properties\">#{props.join}</div>"
            end

            def render_property(name, prop, required, depth, path)
              ref_name = extract_ref_name(prop)
              resolved_prop = resolve_ref(prop)
              return '' unless resolved_prop.is_a?(Hash)

              # Build new path for this property
              current_path = path + [name]
              # Apply filters to this property
              filtered_prop = apply_filters(resolved_prop, current_path)

              metadata = { name: name, required: required, ref_name: ref_name }
              build_property_html(filtered_prop, metadata, depth, current_path)
            end

            def build_property_html(prop, metadata, depth, path)
              has_children = nested_properties?(prop)
              html = [render_node_open(metadata[:name], prop, metadata, depth, has_children)]
              html << render_content_section(prop)
              html << render_children_section(prop, depth, path) if has_children
              html << '</div>'
              html.join
            end

            def render_node_open(name, prop, metadata, depth, has_children)
              required = metadata[:required]
              ref_name = metadata[:ref_name]
              collapsed = depth.positive? ? 'schema-viewer__node--collapsed' : nil
              expandable = has_children ? 'schema-viewer__node--expandable' : nil
              arrow = has_children ? '<span class="schema-viewer__arrow"></span>' : '<span class="schema-viewer__arrow-placeholder"></span>'
              required_badge = required ? '<span class="schema-viewer__required">required</span>' : nil
              ref_badge = ref_name ? "<span class=\"schema-viewer__ref\">→ #{CGI.escapeHTML(ref_name)}</span>".force_encoding('UTF-8') : nil
              header_attrs = build_header_attrs(has_children, depth)

              <<~HTML
                <div class="schema-viewer__node #{collapsed} #{expandable}" data-depth="#{depth}">
                  <div class="schema-viewer__header" #{header_attrs}>
                    #{arrow}
                    <span class="schema-viewer__name">#{CGI.escapeHTML(name)}</span>
                    #{render_type_badge(determine_type(prop))}
                    #{ref_badge}
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

            def render_children_section(prop, depth, path)
              "<div class=\"schema-viewer__children\">#{render_nested_content(prop, depth + 1, path)}</div>"
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

            def render_nested_content(prop, depth, path)
              return render_properties(prop, depth, path) if prop['properties']

              render_properties(resolve_ref(prop['items']), depth, path) if prop['items']
            end

            def apply_filters(schema, path)
              return schema if @filters.empty?
              return schema unless schema.is_a?(Hash)

              # Make a deep copy to avoid mutating original and preserve encoding
              filtered = Marshal.load(Marshal.dump(schema))
              filter_path = path.join('.')

              apply_filter_to_schema(filtered, filter_path) if @filters.key?(filter_path)
              filtered
            end

            def apply_filter_to_schema(schema, filter_path)
              allowed_values = @filters[filter_path]

              filter_enum_values(schema, allowed_values)
              filter_one_of_alternatives(schema, allowed_values)
              filter_any_of_alternatives(schema, allowed_values)
            end

            def filter_enum_values(schema, allowed_values)
              return unless schema['enum'].is_a?(Array)

              schema['enum'] = schema['enum'].select { |v| allowed_values.include?(v.to_s) }
            end

            def filter_one_of_alternatives(schema, allowed_values)
              return unless schema['oneOf'].is_a?(Array)

              schema['oneOf'] = filter_alternatives(schema['oneOf'], allowed_values)
              schema.delete('oneOf') if schema['oneOf'].empty?
            end

            def filter_any_of_alternatives(schema, allowed_values)
              return unless schema['anyOf'].is_a?(Array)

              schema['anyOf'] = filter_alternatives(schema['anyOf'], allowed_values)
              schema.delete('anyOf') if schema['anyOf'].empty?
            end

            def filter_alternatives(alternatives, allowed_values)
              alternatives.select do |alt|
                # Check if alternative has an enum with any allowed values
                if alt['enum'].is_a?(Array)
                  alt['enum'].map(&:to_s).intersect?(allowed_values)
                # Check if alternative has a const matching allowed values
                elsif alt['const']
                  allowed_values.include?(alt['const'].to_s)
                else
                  # Keep alternatives without enum/const
                  true
                end
              end
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
                escaped = CGI.escapeHTML(description)
                "<div class=\"schema-viewer__description\"><span class=\"schema-viewer__description-text\">#{escaped}</span></div>"
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
end
