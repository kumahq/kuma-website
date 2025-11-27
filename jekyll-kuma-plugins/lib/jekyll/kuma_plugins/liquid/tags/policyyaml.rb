# frozen_string_literal: true

# This plugins lets us to write the policy YAML only once.
# It removes duplication of examples for both universal and kubernetes environments.
# The expected format is universal. It only works for policies V2 with a `spec` blocks.
require 'yaml'
require 'rubygems' # Required for Gem::Version
require_relative 'policyyaml/transformers'

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        # TODO: refactor to reduce class size
        # rubocop:disable Metrics/ClassLength
        class PolicyYaml < ::Liquid::Block
          TARGET_VERSION = Gem::Version.new('2.9.0')
          TF_TARGET_VERSION = Gem::Version.new('2.10.0')

          def initialize(tag_name, markup, options)
            super
            @params = { 'raw' => false, 'apiVersion' => 'kuma.io/v1alpha1', 'use_meshservice' => 'false' }
            markup.strip.split.each do |item|
              sp = item.split('=')
              @params[sp[0]] = sp[1] unless sp[1] == ''
            end

            @transformers = [
              PolicyYamlTransformers::MeshServiceTargetRefTransformer.new,
              PolicyYamlTransformers::MeshServiceBackendRefTransformer.new,
              PolicyYamlTransformers::NameTransformer.new,
              PolicyYamlTransformers::KubernetesRootTransformer.new(@params['apiVersion'])
            ]
          end

          def deep_copy(original)
            Marshal.load(Marshal.dump(original))
          end

          def process_node(node, context, path = [])
            if node.is_a?(Hash)
              @transformers.each do |transformer|
                node = transformer.transform(node, context) if transformer.matches?(path, node, context)
              end
              node = node.transform_values.with_index { |v, k| process_node(v, context, path + [node.keys[k]]) }
            elsif node.is_a?(Array)
              node = node.map { |v| process_node(v, context, path) }
            end

            node
          end

          def snake_case(str)
            str.gsub(/([a-z])([A-Z])/, '\1_\2').gsub(/([A-Z])([A-Z][a-z])/, '\1_\2').downcase
          end

          # TODO: refactor to reduce method length
          def yaml_to_terraform(yaml_data)
            type = yaml_data['type']
            name = yaml_data['name']
            resource_name = "konnect_#{snake_case(type)}"
            terraform = "resource \"#{resource_name}\" \"#{name.gsub('-', '_')}\" {\n"
            terraform += terraform_resource_prefix
            yaml_data.each do |key, value|
              next if key == 'mesh' # We use a reference at the end of the provider

              terraform += convert_to_terraform(key, value, 1)
            end
            terraform += terraform_resource_suffix
            terraform += "}\n"
            terraform
          end

          def terraform_resource_prefix
            <<-HEREDOC
  provider = konnect-beta
            HEREDOC
          end

          def terraform_resource_suffix
            <<-HEREDOC
  labels   = {
    "kuma.io/mesh" = konnect_mesh.my_mesh.name
  }
  cp_id    = konnect_mesh_control_plane.my_meshcontrolplane.id
  mesh     = konnect_mesh.my_mesh.name
            HEREDOC
          end

          # TODO: refactor to reduce complexity
          def convert_to_terraform(key, value, indent_level, is_in_array: false, is_last: false)
            key = snake_case(key) unless key.empty?
            indent = '  ' * indent_level
            if value.is_a?(Hash)
              result = is_in_array ? "#{indent}{\n" : "#{indent}#{key} = {\n"
              value.each_with_index do |(k, v), index|
                result += convert_to_terraform(k, v, indent_level + 1, is_last: index == value.size - 1)
              end
              result += "#{indent}}#{is_in_array && !is_last ? ',' : ''}\n"
            elsif value.is_a?(Array)
              result = "#{indent}#{key} = [\n"
              value.each_with_index do |v, index|
                is_last_item = index == value.size - 1
                result += convert_to_terraform('', v, indent_level + 1, is_in_array: true, is_last: is_last_item)
              end
              result += "#{indent}]#{is_in_array && !is_last ? ',' : ''}\n"
            else
              result = "#{indent}#{key} = \"#{value}\"#{is_in_array && !is_last ? ',' : ''}\n"
            end
            result
          end

          # TODO: refactor to reduce complexity
          def render(context)
            content = super
            return '' if content == ''

            has_raw = @body.nodelist.first { |x| x.has?('tag_name') and x.tag_name == 'raw' }

            release = context.registers[:page]['release']
            # remove ```yaml header and ``` footer and read each document one by one
            content = content.gsub(/`{3}yaml\n/, '').gsub(/`{3}/, '')
            site_data = context.registers[:site].config

            version = Gem::Version.new(release.value.dup.sub('x', '0'))
            use_meshservice = @params['use_meshservice'] == 'true' && version >= TARGET_VERSION
            show_tf = version >= TF_TARGET_VERSION

            namespace = @params['namespace'] || site_data['mesh_namespace']
            styles = [
              { name: :uni_legacy, env: :universal, legacy_output: true },
              { name: :uni, env: :universal, legacy_output: false },
              { name: :kube_legacy, env: :kubernetes, legacy_output: true, namespace: namespace },
              { name: :kube, env: :kubernetes, legacy_output: false, namespace: namespace }
            ]

            contents = styles.to_h { |style| [style[:name], ''] }
            terraform_content = ''

            YAML.load_stream(content) do |yaml_data|
              styles.each do |style|
                processed_data = process_node(deep_copy(yaml_data), style)
                contents[style[:name]] += "\n---\n" unless contents[style[:name]] == ''
                contents[style[:name]] += YAML.dump(processed_data).gsub(/^---\n/, '').chomp
                terraform_content += yaml_to_terraform(processed_data) if style[:name] == :uni
              end
            end

            contents = contents.transform_values do |c|
              transformed = "```yaml\n#{c}\n```\n"
              transformed = "{% raw %}\n#{transformed}{% endraw %}\n" if has_raw
              transformed
            end
            terraform_content = "```hcl\n#{terraform_content}\n```\n"
            terraform_content = "{% raw %}\n#{terraform_content}{% endraw %}\n" if has_raw

            version_path = release.value
            version_path = 'dev' if release.label == 'dev'
            edition = context.registers[:page]['edition']
            docs_path = "/#{edition}/#{version_path}"
            docs_path = "/docs/#{version_path}" if edition == 'kuma'
            additional_classes = 'codeblock' unless use_meshservice

            # Conditionally render tabs based on use_meshservice
            html_content = "
{% tabs #{additional_classes} %}"

            html_content += if use_meshservice
                              "
{% tab Kubernetes %}
<div class=\"meshservice\">
 <label> <input type=\"checkbox\"> I am using <a href=\"#{docs_path}/networking/meshservice/\">MeshService</a> </label>
</div>
#{contents[:kube_legacy]}
#{contents[:kube]}
{% endtab %}
{% tab Universal %}
<div class=\"meshservice\">
 <label> <input type=\"checkbox\"> I am using <a href=\"#{docs_path}/networking/meshservice/\">MeshService</a> </label>
</div>
#{contents[:uni_legacy]}
#{contents[:uni]}
{% endtab %}"
                            else
                              "
{% tab Kubernetes %}
#{contents[:kube_legacy]}
{% endtab %}
{% tab Universal %}
#{contents[:uni_legacy]}
{% endtab %}"
                            end

            if edition != 'kuma' && show_tf
              html_content += "
{% tab Terraform %}
<div style=\"margin-top: 4rem; padding: 0 1.3rem\">
Please adjust <b>konnect_mesh_control_plane.my_meshcontrolplane.id</b> and
<b>konnect_mesh.my_mesh.name</b> according to your current configuration
</div>
#{terraform_content}
{% endtab %}"
            end

            html_content += '{% endtabs %}'

            # Return the final HTML content
            ::Liquid::Template.parse(html_content).render(context)
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('policy_yaml', Jekyll::KumaPlugins::Liquid::Tags::PolicyYaml)
