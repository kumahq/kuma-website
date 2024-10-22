# This plugins lets us to write the policy YAML only once.
# It removes duplication of examples for both universal and kubernetes environments.
# The expected format is universal. It only works for policies V2 with a `spec` blocks.
require 'yaml'
require 'rubygems'  # Required for Gem::Version

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class PolicyYaml < ::Liquid::Block
          TARGET_VERSION = Gem::Version.new("2.9.0")

          def initialize(tag_name, markup, options)
            super
            @tabs_name, *params_list = @markup.split(' ')
            @params = {"raw" => false, "apiVersion" => "kuma.io/v1alpha1", "use_meshservice" => "false" }
            params_list.each do |item|
                sp = item.split('=')
                @params[sp[0]] = sp[1] unless sp[1] == ''
            end
          end

          def to_legacy_meshservice_target_ref(hash)
            # Transform each element in spec.to[].targetRef.kind if spec.to exists
            if hash.dig("spec", "to").is_a?(Array)
              hash["spec"]["to"].each do |to_item|
                if to_item.dig("targetRef", "kind") == "MeshService"
                  target_ref = to_item["targetRef"]
                  if hash.key?("apiVersion")
                    port = target_ref['port'].to_s
                    namespace = target_ref['namespace'].to_s
                    to_item["targetRef"] = {
                      "kind" => "MeshService",
                      "name" => target_ref['name'] + "_" + namespace + "_" + port,
                    }
                  else
                    to_item["targetRef"].delete("sectionName")
                    to_item["targetRef"].delete("section_name")
                  end
                  to_item["targetRef"].delete("namespace")
                  to_item["targetRef"].delete("port")
                end
              end
            end
          end

          def clean_up_meshservice_target_ref(hash)
            # Transform each element in spec.to[].targetRef.kind if spec.to exists
            if hash.dig("spec", "to").is_a?(Array)
              hash["spec"]["to"].each do |to_item|
                if to_item.dig("targetRef", "kind") == "MeshService"
                  if !hash.key?("apiVersion")
                    to_item["targetRef"].delete("namespace")
                  end
                  to_item["targetRef"].delete("port")
                end
              end
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
                process_hash(value, remove_suffix, rename_suffix)  # Recursive call for nested hash
              elsif value.is_a?(Array)
                process_array(value, remove_suffix, rename_suffix)  # Recursive call for nested array
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
              if item.is_a?(Hash)
                process_hash(item, remove_suffix, rename_suffix)  # Recursive call for nested hash in array
              elsif item.is_a?(Array)
                process_array(item, remove_suffix, rename_suffix)  # Recursive call for nested array
              end
            end
          end

          def version_supported(version)
            return true if version == "dev"

            current_version = Gem::Version.new(version)
            current_version > TARGET_VERSION
          end

          def render(context)
            content = super
            return "" if content == ""
            has_raw = @body.nodelist.first { |x| x.has?("tag_name") and x.tag_name == "raw"}

            version = context.registers[:page]['version']
            # remove ```yaml header and ``` footer and read each document one by one
            content = content.gsub(/`{3}yaml\n/, '').gsub(/`{3}/, '')
            site_data = context.registers[:site].config
            mesh_namespace = @params["namespace"] || site_data['mesh_namespace']

            uni_style1_content = ""
            uni_style2_content = ""
            kube_style1_content = ""
            kube_style2_content = ""

            use_meshservice = @params["use_meshservice"] == "true" && version_supported(version)

            YAML.load_stream(content) do |yaml_data|
              uni_style1_data = Marshal.load(Marshal.dump(yaml_data))
              uni_style2_data = Marshal.load(Marshal.dump(yaml_data))
              to_legacy_meshservice_target_ref(uni_style1_data) if use_meshservice
              clean_up_meshservice_target_ref(uni_style2_data)

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
              kube_style2_data = Marshal.load(Marshal.dump(kube_style1_data))
              to_legacy_meshservice_target_ref(kube_style1_data) if use_meshservice
              clean_up_meshservice_target_ref(kube_style2_data)

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
