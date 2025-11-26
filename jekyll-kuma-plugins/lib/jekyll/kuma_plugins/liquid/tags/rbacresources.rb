# frozen_string_literal: true

# This plugin generates tabbed tables for RBAC resources (ClusterRole, ClusterRoleBinding,
# Role, RoleBinding) from a given YAML file. Each tab corresponds to a resource kind,
# and each resource is shown in a nested tab with its name and YAML content.
#
# When no `filename` is provided, the plugin uses `rbac.yaml` by default.
# The plugin looks for the file using the following logic:
#
# 1. It reads the current release from `page.release`.
# 2. It looks for the file in each path configured in `mesh_raw_generated_paths`
#    in the site's `_config.yml`. If not set, it defaults to: ['app/assets'].
# 3. For each base path, it checks if the file exists at:
#       {{ base_path }}/{{ release }}/raw/{{ filename }}
# 4. If not found, it falls back to checking if the provided filename is an absolute or relative path.
# 5. If still not found, the plugin raises an error.
#
# Usage examples:
#   {% rbacresources %}                            # uses default filename `rbac.yaml`
#   {% rbacresources filename=custom-rbac.yaml %}  # uses a custom filename

require 'yaml'

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class RbacResources < ::Liquid::Tag
          PATHS_CONFIG = 'mesh_raw_generated_paths'
          DEFAULT_PATHS = ['app/assets'].freeze
          DEFAULT_FILENAME = 'rbac.yaml'

          def initialize(tag_name, text, tokens)
            super
            @markup = text.strip
            @params = { 'filename' => DEFAULT_FILENAME }

            @markup.split.each do |item|
              key, value = item.split('=')
              @params[key] = value.strip.gsub(/^"+|"+$/, '') if key && value
            end
          end

          RBAC_KINDS = %w[ClusterRole ClusterRoleBinding Role RoleBinding].freeze

          def render(context)
            filename = resolve_file_path(context)
            yaml_content = YAML.load_stream(File.read(filename))
            grouped = filter_rbac_resources(yaml_content)
            tab_output = grouped.map { |kind, docs| generate_kind_tab(kind, docs) }.join("\n")

            ::Liquid::Template.parse(<<~MARKDOWN).render(context)
              {% tabs %}
              #{tab_output}
              {% endtabs %}
            MARKDOWN
          end

          private

          def filter_rbac_resources(yaml_content)
            yaml_content
              .select { |doc| doc.is_a?(Hash) && RBAC_KINDS.include?(doc['kind']) }
              .group_by { |doc| doc['kind'] }
          end

          def generate_kind_tab(kind, docs)
            subtabs = docs.map { |doc| generate_resource_subtab(kind, doc) }.join("\n")
            <<~TAB
              {% tab #{kind} %}
              {% tabs codeblock %}
              #{subtabs}
              {% endtabs %}
              {% endtab %}
            TAB
          end

          def generate_resource_subtab(kind, doc)
            name = doc.dig('metadata', 'name')
            raise ArgumentError, "RBAC resource of kind '#{kind}' is missing a non-empty metadata.name" if name.nil? || name.strip.empty?

            yaml = YAML.dump(doc).lines.reject { |line| line.strip == '---' }.join.strip
            <<~SUBTAB
              {% tab #{name} %}
              ```yaml
              #{yaml}
              ```
              {:.no-line-numbers}
              {% endtab %}
            SUBTAB
          end

          def resolve_file_path(context)
            site_config = context.registers[:site].config
            page_data = context.registers[:page]
            release = page_data['release'].to_s.strip
            base_paths = site_config.fetch(PATHS_CONFIG, DEFAULT_PATHS)

            base_paths.each do |base_path|
              candidate = File.join(base_path, release, 'raw', @params['filename'])
              return candidate if File.exist?(candidate)
            end

            fallback = @params['filename']
            return fallback if File.exist?(fallback)

            raise ArgumentError,
                  "File not found: #{@params['filename']} (searched in configured paths and as absolute path)"
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('rbacresources', Jekyll::KumaPlugins::Liquid::Tags::RbacResources)
