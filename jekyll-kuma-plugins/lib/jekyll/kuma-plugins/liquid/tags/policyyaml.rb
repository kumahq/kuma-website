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
                      "name" => [target_ref['name'], target_ref['namespace'], target_ref['port']].compact.join('_')
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
            uni_style1_content = ""
            uni_style2_content = ""
            kube_style1_content = ""
            kube_style2_content = ""

            YAML.load_stream(content) do |yaml_data|
              uni_style1_data = process_node(deep_copy(yaml_data), { env: :universal, legacy_output: true })
              uni_style2_data = process_node(deep_copy(yaml_data), { env: :universal, legacy_output: false })
              kube_style1_data = process_node(deep_copy(yaml_data), { env: :kubernetes, legacy_output: true, namespace: namespace })
              kube_style2_data = process_node(deep_copy(yaml_data), { env: :kubernetes, legacy_output: false, namespace: namespace })

              # Build the YAML content for all four styles
              uni_style1_content += "\n---\n" unless uni_style1_content == ''
              uni_style1_content += YAML.dump(uni_style1_data).gsub(/^---\n/, '').chomp

              uni_style2_content += "\n---\n" unless uni_style2_content == ''
              uni_style2_content += YAML.dump(uni_style2_data).gsub(/^---\n/, '').chomp

              kube_style1_content += "\n---\n" unless kube_style1_content == ''
              kube_style1_content += YAML.dump(kube_style1_data).gsub(/^---\n/, '').chomp

              kube_style2_content += "\n---\n" unless kube_style2_content == ''
              kube_style2_content += YAML.dump(kube_style2_data).gsub(/^---\n/, '').chomp
            end

            # Wrap YAML content in code blocks
            uni_style1_content = "```yaml\n" + uni_style1_content + "\n```\n"
            uni_style2_content = "```yaml\n" + uni_style2_content + "\n```\n"
            kube_style1_content = "```yaml\n" + kube_style1_content + "\n```\n"
            kube_style2_content = "```yaml\n" + kube_style2_content + "\n```\n"

            if has_raw != false
              uni_style1_content = "{% raw %}\n" + uni_style1_content + "{% endraw %}\n"
              uni_style2_content = "{% raw %}\n" + uni_style2_content + "{% endraw %}\n"
              kube_style1_content = "{% raw %}\n" + kube_style1_content + "{% endraw %}\n"
              kube_style2_content = "{% raw %}\n" + kube_style2_content + "{% endraw %}\n"
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
#{kube_style1_content}
#{kube_style2_content}
{% endtab %}
{% tab #{@tabs_name} Universal %}
<div class=\"meshservice\">
 <label> <input type=\"checkbox\"> I am using <a href=\"/docs/" + version + "/networking/meshservice/\">MeshService</a> </label>
</div>
#{uni_style1_content}
#{uni_style2_content}
{% endtab %}"
            else
            htmlContent += "
{% tab #{@tabs_name} Kubernetes %}
#{kube_style1_content}
{% endtab %}
{% tab #{@tabs_name} Universal %}
#{uni_style1_content}
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
