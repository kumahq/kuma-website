require 'yaml'

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class PolicyYaml < ::Liquid::Block
          def initialize(tag_name, markup, options)
            super
            @tabs_name, *params_list = markup.split(' ')
            @default_params = { "raw" => false, "apiVersion" => "kuma.io/v1alpha1", "use_meshservice" => "false" }
            # Params are initialized per block
            @params = Marshal.load(Marshal.dump(@default_params))
            params_list.each do |item|
              key, value = item.split('=')
              @params[key] = value unless value == ''
            end
          end

          # Function to transform targetRef based on MeshService name (if needed)
          def transform_target_ref(hash)
            if hash.dig("spec", "targetRef", "kind") == "MeshService"
              target_ref = hash["spec"]["targetRef"]
              if target_ref["name_kube"]
                transformed_name = target_ref["name_kube"].split('_')
                hash["spec"]["targetRef"] = {
                  "kind" => "MeshService",
                  "name" => transformed_name[0],
                  "namespace" => transformed_name[1],
                  "sectionName" => transformed_name[3]
                }
              elsif target_ref["name_uni"]
                hash["spec"]["targetRef"]["name"] = target_ref["name_uni"]
                hash["spec"]["targetRef"].delete("name_uni")
                hash["spec"]["targetRef"].delete("name_kube")
              end
            end
          end

          # Function to remove and rename suffixes in the YAML block (_uni, _kube)
          def process_hash(hash, remove_suffix, rename_suffix)
            keys_to_remove = []
            keys_to_rename = {}

            hash.each do |key, value|
              if value.is_a?(Hash)
                process_hash(value, remove_suffix, rename_suffix)
              elsif value.is_a?(Array)
                process_array(value, remove_suffix, rename_suffix)
              end

              # Remove keys with the specific suffix
              if key.end_with?(remove_suffix)
                keys_to_remove << key
              elsif key.end_with?(rename_suffix)
                # Rename keys to remove the suffix
                new_key = key.sub(/#{rename_suffix}\z/, '')
                keys_to_rename[key] = new_key
              end
            end

            keys_to_remove.each { |key| hash.delete(key) }
            keys_to_rename.each { |old_key, new_key| hash[new_key] = hash.delete(old_key) }
          end

          def process_array(array, remove_suffix, rename_suffix)
            array.each do |item|
              process_hash(item, remove_suffix, rename_suffix) if item.is_a?(Hash)
              process_array(item, remove_suffix, rename_suffix) if item.is_a?(Array)
            end
          end

          def render(context)
            content = super
            return "" if content == ""

            content = content.gsub(/`{3}yaml\n/, '').gsub(/`{3}/, '')
            site_data = context.registers[:site].config
            mesh_namespace = @params["namespace"] || site_data['mesh_namespace']

            uni_style1_content = ""
            uni_style2_content = ""
            kube_style1_content = ""
            kube_style2_content = ""

            # Re-initialize params to ensure no cross-block contamination
            params = Marshal.load(Marshal.dump(@params))
            use_meshservice = params["use_meshservice"] == "true"

            YAML.load_stream(content) do |yaml_data|
              # Universal Style 1 (without transformation)
              uni_style1_data = Marshal.load(Marshal.dump(yaml_data))

              # Universal Style 2 (with transformation, if applicable)
              uni_style2_data = Marshal.load(Marshal.dump(yaml_data))
              transform_target_ref(uni_style2_data) if use_meshservice

              # Kubernetes Style 1 (without transformation)
              kube_style1_data = {
                "apiVersion" => params["apiVersion"],
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

              # Kubernetes Style 2 (with transformation, if applicable)
              kube_style2_data = Marshal.load(Marshal.dump(kube_style1_data))
              transform_target_ref(kube_style2_data) if use_meshservice

              # Handle suffix removal for universal and kubernetes variations
              process_hash(kube_style1_data, "_uni", "_kube")
              process_hash(kube_style2_data, "_uni", "_kube")
              process_hash(uni_style1_data, "_kube", "_uni")
              process_hash(uni_style2_data, "_kube", "_uni")

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

            # Conditionally render tabs based on use_meshservice
            htmlContent = "
{% tabs #{@tabs_name} useUrlFragment=false %}"


            if use_meshservice
              htmlContent += "
{% tab #{@tabs_name} Kubernetes %}
<div class=\"meshservice\">
  I am using <a href=\"\">MeshService</a> <input type=\"checkbox\">
</div>
#{kube_style1_content}
#{kube_style2_content}
{% endtab %}
{% tab #{@tabs_name} Universal %}
<div class=\"meshservice\">
  I am using <a href=\"\">MeshService</a> <input type=\"checkbox\">
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
