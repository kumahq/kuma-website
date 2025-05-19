# This plugin generates tabbed tables for RBAC resources (ClusterRole, ClusterRoleBinding,
# Role, RoleBinding) from a given YAML file. Each tab corresponds to a resource kind.
# Each resource is shown in a nested tab with its name and YAML content.
#
# Usage: {% rbacresources filename=path/to/file.yaml %}

require 'yaml'

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class RbacResources < ::Liquid::Tag
          def initialize(tag_name, text, tokens)
            super
            @markup = text.strip
            @params = { "filename" => nil }

            @markup.split(' ').each do |item|
              key, value = item.split('=')
              @params[key] = value.strip.gsub(/^"+|"+$/, '') if key && value
            end

            unless @params["filename"] && File.exist?(@params["filename"])
              raise ArgumentError, "Valid 'filename' parameter required for rbacresources tag."
            end
          end

          def render(context)
            ::Liquid::Template.parse(content).render(context)
          end

          private

          def content
            yaml_content = YAML.load_stream(File.read(@params["filename"]))
            grouped = yaml_content
              .select { |doc| doc.is_a?(Hash) && %w[ClusterRole ClusterRoleBinding Role RoleBinding].include?(doc["kind"]) }
              .group_by { |doc| doc["kind"] }

            tab_output = grouped.map do |kind, docs|
              subtabs = docs.map do |doc|
                name = doc.dig("metadata", "name")
                if name.nil? || name.strip.empty?
                  raise ArgumentError, "RBAC resource of kind '#{kind}' is missing a non-empty metadata.name"
                end

                yaml = YAML.dump(doc).lines.reject { |line| line.strip == "---" }.join.strip
                <<~SUBTAB
                  {% tab #{name} %}
                  ```yaml
                  #{yaml}
                  ```
                  {:.no-line-numbers}
                  {% endtab %}
                SUBTAB
              end.join("\n")

              <<~TAB
                {% tab #{kind} %}
                {% tabs codeblock %}
                #{subtabs}
                {% endtabs %}
                {% endtab %}
              TAB
            end.join("\n")

            <<~MARKDOWN
              {% tabs %}
              #{tab_output}
              {% endtabs %}
            MARKDOWN
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('rbacresources', Jekyll::KumaPlugins::Liquid::Tags::RbacResources)
