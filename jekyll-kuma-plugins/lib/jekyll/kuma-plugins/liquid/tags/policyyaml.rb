# This plugins lets us to write the policy YAML only once.
# It removes duplication of examples for both universal and kubernetes environments.
# The expected format is universal. It only works for policies V2 with a `spec` blocks.
require 'yaml'
require 'rubygems' # Required for Gem::Version

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class PolicyYaml < ::Liquid::Block
          TARGET_VERSION = Gem::Version.new("2.9.0")

          def has_path(path)
            ->(node_path, _, _) { node_path == path }
          end

          def root_path
            has_path([])
          end

          def kind_is(kind)
            ->(_, node, _) { node['kind'] == kind }
          end

          def _and(*conditions)
            ->(node_path, node, context) { conditions.all? { |cond| cond.call(node_path, node, context) } }
          end

          def _or(*conditions)
            ->(node_path, node, context) { conditions.any? { |cond| cond.call(node_path, node, context) } }
          end

          def has_field(field_name)
            ->(_, node, _) { node.key?(field_name) }
          end

          def is_kubernetes
            ->(_, _, context) { context[:env] == :kubernetes }
          end

          def initialize(tag_name, markup, options)
            super
            @tabs_name, *params_list = @markup.split(' ')
            @params = { "raw" => false, "apiVersion" => "kuma.io/v1alpha1", "use_meshservice" => "false" }
            params_list.each do |item|
              sp = item.split('=')
              @params[sp[0]] = sp[1] unless sp[1] == ''
            end

            @callbacks = []

            register_callback(
              _and(has_path(%w[spec to targetRef]), kind_is("MeshService")),
              lambda do |target_ref, context|
                case context[:env]
                when :kubernetes
                  if context[:legacy_output]
                    {
                      "kind" => "MeshService",
                      "name" => [target_ref['name'], target_ref['namespace'], target_ref['_port']].compact.join('_')
                    }
                  else
                    {
                      "kind" => "MeshService",
                      "name" => target_ref['name'],
                      "namespace" => target_ref['namespace'],
                      "sectionName" => target_ref['sectionName']
                    }
                  end
                when :universal
                  if context[:legacy_output]
                    {
                      "kind" => "MeshService",
                      "name" => target_ref['name']
                    }
                  else
                    {
                      "kind" => "MeshService",
                      "name" => target_ref['name'],
                      "sectionName" => target_ref['sectionName']
                    }
                  end
                end
              end)

            register_callback(
              _or(has_field("name_uni"), has_field("name_kube")),
              lambda do |node, context|
                node_copy = deep_copy(node)
                node_copy.delete("name_uni")
                node_copy.delete("name_kube")

                case context[:env]
                when :kubernetes
                  node_copy["name"] = node["name_kube"]
                when :universal
                  node_copy["name"] = node["name_uni"]
                end

                node_copy
              end)

            register_callback(
              _and(root_path, is_kubernetes),
              lambda do |node, context|
                {
                  "apiVersion" => @params["apiVersion"],
                  "kind" => node["type"],
                  "metadata" => {
                    "name" => node["name"],
                    "namespace" => context[:namespace],
                    "labels" => {
                      **(node["labels"] || {}),
                      "kuma.io/mesh" => node["mesh"]
                    }
                  },
                  "spec" => node["spec"]
                }
              end)
          end

          # Register a callback to be executed when a node matches a condition
          def register_callback(condition, callback)
            @callbacks << [condition, callback]
          end

          def version_supported(version)
            return true if version == "dev"

            current_version = Gem::Version.new(version)
            current_version > TARGET_VERSION
          end

          def deep_copy(original)
            Marshal.load(Marshal.dump(original))
          end

          def process_node(node, context, path = [])
            if node.is_a?(Hash)
              @callbacks.each do |condition, callback|
                if condition.call(path, node, context)
                  node = callback.call(node, context)
                end
              end
              node = node.transform_values.with_index { |v, k| process_node(v, context, path + [node.keys[k]]) }
            elsif node.is_a?(Array)
              node = node.map { |v| process_node(v, context, path) }
            end

            node
          end

          def render(context)
            content = super
            return "" if content == ""
            has_raw = @body.nodelist.first { |x| x.has?("tag_name") and x.tag_name == "raw" }

            version = context.registers[:page]['version']
            # remove ```yaml header and ``` footer and read each document one by one
            content = content.gsub(/`{3}yaml\n/, '').gsub(/`{3}/, '')
            site_data = context.registers[:site].config

            use_meshservice = @params["use_meshservice"] == "true" && version_supported(version)

            namespace = @params["namespace"] || site_data['mesh_namespace']
            styles = [
              { name: :uni_legacy, env: :universal, legacy_output: true },
              { name: :uni, env: :universal, legacy_output: false },
              { name: :kube_legacy, env: :kubernetes, legacy_output: true, namespace: namespace },
              { name: :kube, env: :kubernetes, legacy_output: false, namespace: namespace }
            ]

            contents = styles.map { |style| [style[:name], ""] }.to_h

            YAML.load_stream(content) do |yaml_data|
              styles.each do |style|
                processed_data = process_node(deep_copy(yaml_data), style)
                contents[style[:name]] += "\n---\n" unless contents[style[:name]] == ''
                contents[style[:name]] += YAML.dump(processed_data).gsub(/^---\n/, '').chomp
              end
            end

            contents = contents.transform_values do |c|
              transformed = "```yaml\n#{c}\n```\n"
              transformed = "{% raw %}\n#{transformed}{% endraw %}\n" if has_raw
              transformed
            end

            # Conditionally render tabs based on use_meshservice
            htmlContent = "
{% tabs #{@tabs_name} useUrlFragment=false %}"

            if use_meshservice
              htmlContent += "
{% tab #{@tabs_name} Kubernetes %}
<div class=\"meshservice\">
 <label> <input type=\"checkbox\"> I am using <a href=\"/docs/" + version + "/networking/meshservice/\">MeshService</a> </label>
</div>
#{contents[:kube_legacy]}
#{contents[:kube]}
{% endtab %}
{% tab #{@tabs_name} Universal %}
<div class=\"meshservice\">
 <label> <input type=\"checkbox\"> I am using <a href=\"/docs/" + version + "/networking/meshservice/\">MeshService</a> </label>
</div>
#{contents[:uni_legacy]}
#{contents[:uni]}
{% endtab %}"
            else
              htmlContent += "
{% tab #{@tabs_name} Kubernetes %}
#{contents[:kube_legacy]}
{% endtab %}
{% tab #{@tabs_name} Universal %}
#{contents[:uni_legacy]}
{% endtab %}"
            end

            htmlContent += "{% endtabs %}"

            # Return the final HTML content
            ::Liquid::Template.parse(htmlContent).render(context)
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('policy_yaml', Jekyll::KumaPlugins::Liquid::Tags::PolicyYaml)
