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
#    When `page.release` is blank, it falls back to:
#       {{ base_path }}/raw/{{ filename }}
# 4. If still not found in the configured paths, the plugin raises an error.
#    It does not fall back to arbitrary absolute or relative filesystem paths.
#
# Usage examples:
#   {% rbacresources %}                            # uses default filename `rbac.yaml`
#   {% rbacresources filename=custom-rbac.yaml %}  # uses a custom filename

require 'yaml'
require_relative '../../common/path_helpers'

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        # Renders RBAC resources from a YAML file rooted in the configured raw asset paths.
        class RbacResources < ::Liquid::Tag
          include Jekyll::KumaPlugins::Common::PathHelpers

          DEFAULT_FILENAME = 'rbac.yaml'
          SAFE_YAML_OPTIONS = {
            permitted_classes: [],
            aliases: false
          }.freeze

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
            yaml_content = YAML.safe_load_stream(read_rbac_file(context), **SAFE_YAML_OPTIONS)
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

          def read_rbac_file(context)
            site_config = context.registers[:site].config
            page_data = context.registers[:page]
            release = optional_path_segment(page_data['release'])
            base_paths = site_config.fetch(PATHS_CONFIG, DEFAULT_PATHS)

            read_file_content(base_paths, build_relative_path(release, 'raw', @params['filename']))
          rescue RuntimeError => e
            raise unless e.message.start_with?("couldn't read ")

            raise ArgumentError, "File not found: #{@params['filename']} (searched in configured paths: #{base_paths})"
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('rbacresources', Jekyll::KumaPlugins::Liquid::Tags::RbacResources)
