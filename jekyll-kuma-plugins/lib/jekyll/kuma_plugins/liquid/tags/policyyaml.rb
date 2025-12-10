# frozen_string_literal: true

# This plugins lets us to write the policy YAML only once.
# It removes duplication of examples for both universal and kubernetes environments.
# The expected format is universal. It only works for policies V2 with a `spec` blocks.
require 'yaml'
require 'rubygems' # Required for Gem::Version
require_relative 'policyyaml/transformers'
require_relative 'policyyaml/terraform_generator'
require_relative 'policyyaml/tab_generator'

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class PolicyYaml < ::Liquid::Block
          TARGET_VERSION = Gem::Version.new('2.9.0')
          TF_TARGET_VERSION = Gem::Version.new('2.10.0')

          def initialize(tag_name, markup, options)
            super
            @params = { 'raw' => false, 'apiVersion' => 'kuma.io/v1alpha1', 'use_meshservice' => 'false' }
            parse_markup(markup)
            register_default_transformers
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

          def render(context)
            content = super
            return '' if content == ''

            render_context = build_render_context(context, content)
            contents, terraform_content = process_yaml_content(render_context)
            html = TabGenerator.new.generate(render_context, contents, terraform_content)
            ::Liquid::Template.parse(html).render(context)
          end

          private

          def parse_markup(markup)
            markup.strip.split.each do |item|
              sp = item.split('=')
              @params[sp[0]] = sp[1] unless sp[1] == ''
            end
          end

          def register_default_transformers
            @transformers = [
              PolicyYamlTransformers::MeshServiceTargetRefTransformer.new,
              PolicyYamlTransformers::MeshServiceBackendRefTransformer.new,
              PolicyYamlTransformers::NameTransformer.new,
              PolicyYamlTransformers::KubernetesRootTransformer.new(@params['apiVersion'])
            ]
          end

          def build_render_context(context, content)
            has_raw = @body.nodelist.first { |x| x.has?('tag_name') and x.tag_name == 'raw' }
            release = context.registers[:page]['release']
            site_data = context.registers[:site].config
            version = Gem::Version.new(release.value.dup.sub('x', '0'))

            {
              has_raw: has_raw,
              release: release,
              site_data: site_data,
              version: version,
              use_meshservice: @params['use_meshservice'] == 'true' && version >= TARGET_VERSION,
              show_tf: version >= TF_TARGET_VERSION,
              namespace: @params['namespace'] || site_data['mesh_namespace'],
              content: content.gsub(/`{3}yaml\n/, '').gsub(/`{3}/, ''),
              edition: context.registers[:page]['edition']
            }
          end

          def process_yaml_content(render_context)
            styles = build_styles(render_context[:namespace])
            contents = styles.to_h { |style| [style[:name], ''] }
            terraform_content = ''
            terraform_generator = TerraformGenerator.new

            YAML.load_stream(render_context[:content]) do |yaml_data|
              styles.each do |style|
                processed_data = process_node(deep_copy(yaml_data), style)
                contents[style[:name]] += "\n---\n" unless contents[style[:name]] == ''
                contents[style[:name]] += YAML.dump(processed_data).gsub(/^---\n/, '').chomp
                terraform_content += terraform_generator.generate(processed_data) if style[:name] == :uni
              end
            end

            contents = wrap_yaml_contents(contents, render_context[:has_raw])
            terraform_content = wrap_terraform_content(terraform_content, render_context[:has_raw])

            [contents, terraform_content]
          end

          def build_styles(namespace)
            [
              { name: :uni_legacy, env: :universal, legacy_output: true },
              { name: :uni, env: :universal, legacy_output: false },
              { name: :kube_legacy, env: :kubernetes, legacy_output: true, namespace: namespace },
              { name: :kube, env: :kubernetes, legacy_output: false, namespace: namespace }
            ]
          end

          def wrap_yaml_contents(contents, has_raw)
            contents.transform_values { |c| wrap_content(c, 'yaml', has_raw) }
          end

          def wrap_terraform_content(content, has_raw)
            wrap_content(content, 'hcl', has_raw)
          end

          def wrap_content(content, lang, has_raw)
            wrapped = "```#{lang}\n#{content}\n```\n"
            has_raw ? "{% raw %}\n#{wrapped}{% endraw %}\n" : wrapped
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('policy_yaml', Jekyll::KumaPlugins::Liquid::Tags::PolicyYaml)
