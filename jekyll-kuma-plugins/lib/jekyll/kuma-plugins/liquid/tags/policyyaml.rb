# This plugins lets us to write the policy YAML only once.
# It removes duplication of examples for both universal and kubernetes environments.
# The expected format is universal. It only works for policies V2 with a `spec` blocks.
require 'yaml'
module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class PolicyYaml < ::Liquid::Block
          def initialize(tag_name, markup, options)
            super
            @tabs_name, *params_list = @markup.split(' ')
            @params = {"raw" => false, "apiVersion" => "kuma.io/v1alpha1", "use_meshservice" => "false"} # Default use_meshservice to false
            params_list.each do |item|
                sp = item.split('=')
                @params[sp[0]] = sp[1] unless sp[1] == ''
            end
          end

          # Transform targetRef if the kind is MeshService, combining namespace, name, and sectionName
          def transform_target_ref(hash)
            if hash.dig("spec", "targetRef", "kind") == "MeshService"
              target_ref = hash["spec"]["targetRef"]
              transformed_name = "#{target_ref['name']}_#{target_ref['namespace']}_svc_#{target_ref['sectionName']}"
              hash["spec"]["targetRef"] = {
                "kind" => "MeshService",
                "name" => transformed_name
              }
            end
          end

		  # process_hash and process_array are recursive functions that remove the suffixes from the keys
		  # and rename the keys that have the suffixes.
		  # For example, if you have keys called `name_uni` and `name_kube`:
		  # on universal - `name_uni` -> `name` and `name_kube` will be removed
		  # on kubernetes - `name_kube` -> `name` and `name_uni` will be removed
          def process_hash(hash, remove_suffix, rename_suffix)
            keys_to_remove = []
            keys_to_rename = {}

            hash.each do |key, value|
              if value.is_a?(Hash)
                process_hash(value, remove_suffix, rename_suffix)
              elsif value.is_a?(Array)
                process_array(value, remove_suffix, rename_suffix)
              end

              if key.end_with?(remove_suffix)
                keys_to_remove << key
              elsif key.end_with?(rename_suffix)
                new_key = key.sub(/#{rename_suffix}\z/, '')
                keys_to_rename[key] = new_key
              end
            end

            keys_to_remove.each { |key| hash.delete(key) }
            keys_to_rename.each { |old_key, new_key| hash[new_key] = hash.delete(old_key) }
          end

          def process_array(array, remove_suffix, rename_suffix)
            array.each do |item|
              if item.is_a?(Hash)
                process_hash(item, remove_suffix, rename_suffix)
              elsif item.is_a?(Array)
                process_array(item, remove_suffix, rename_suffix)
              end
            end
          end

          def render(context)
            content = super
            return "" if content == ""
            has_raw = @body.nodelist.first { |x| x.has?("tag_name") and x.tag_name == "raw"}
            content = content.gsub(/`{3}yaml\n/, '').gsub(/`{3}/, '')
            site_data = context.registers[:site].config
            mesh_namespace = site_data['mesh_namespace']

            uni_style1_content = ""
            uni_style2_content = ""
            kube_style1_content = ""
            kube_style2_content = ""

            use_meshservice = @params["use_meshservice"] == "true" # Check if use_meshservice is enabled
            YAML.load_stream(content) do |yaml_data|
                # Universal Style 1 (Original targetRef)
                uni_style1_data = Marshal.load(Marshal.dump(yaml_data))

                # Universal Style 2 (Transformed targetRef) only if use_meshservice is enabled
                uni_style2_data = Marshal.load(Marshal.dump(yaml_data))
                transform_target_ref(uni_style2_data) if use_meshservice

                # Kubernetes Style 1 (Original targetRef)
                kube_style1_data = {
                  "apiVersion" => @params["apiVersion"],
                  "kind" => yaml_data["type"],
                  "metadata" => {
                    "name" => yaml_data["name"],
                    "namespace" => mesh_namespace,
                    "labels" => {
                      **(yaml_data["labels"] || {}),
                      "kuma.io/mesh" => yaml_data["mesh"]
                    }
                  },
                  "spec" => yaml_data["spec"]
                }

                # Kubernetes Style 2 (Transformed targetRef) only if use_meshservice is enabled
                kube_style2_data = Marshal.load(Marshal.dump(kube_style1_data))
                transform_target_ref(kube_style2_data) if use_meshservice

                # Process hashes to remove suffixes (e.g., _uni, _kube)
                process_hash(kube_style1_data, "_uni", "_kube")
                process_hash(kube_style2_data, "_uni", "_kube")

                process_hash(uni_style1_data, "_kube", "_uni")
                process_hash(uni_style2_data, "_kube", "_uni")

                # Generate YAML content for each style
                uni_style1_content += "\n---\n" unless uni_style1_content == ''
                uni_style1_content += YAML.dump(uni_style1_data).gsub(/^---\n/, '').chomp

                uni_style2_content += "\n---\n" unless uni_style2_content == ''
                uni_style2_content += YAML.dump(uni_style2_data).gsub(/^---\n/, '').chomp

                kube_style1_content += "\n---\n" unless kube_style1_content == ''
                kube_style1_content += YAML.dump(kube_style1_data).gsub(/^---\n/, '').chomp

                kube_style2_content += "\n---\n" unless kube_style2_content == ''
                kube_style2_content += YAML.dump(kube_style2_data).gsub(/^---\n/, '').chomp
            end

            # Wrap the content in YAML code blocks
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

            # Create the four tabs in HTML
            htmlContent = "
{% tabs #{@tabs_name} useUrlFragment=false %}
{% tab #{@tabs_name} Kubernetes (Style 1) %}
#{kube_style1_content}
{% endtab %}
{% tab #{@tabs_name} Kubernetes (Style 2) %}
#{kube_style2_content}
{% endtab %}
{% tab #{@tabs_name} Universal (Style 1) %}
#{uni_style1_content}
{% endtab %}
{% tab #{@tabs_name} Universal (Style 2) %}
#{uni_style2_content}
{% endtab %}
{% endtabs %}"

            ::Liquid::Template.parse(htmlContent).render(context)
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('policy_yaml', Jekyll::KumaPlugins::Liquid::Tags::PolicyYaml)
