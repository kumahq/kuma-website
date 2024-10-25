# This plugin generates a code block with YAML for Helm's values.yaml file, nesting the YAML content under the specified prefix path.
# For example, if the prefix path is "foo.bar.baz" and the YAML content is:
# ```yaml
# a:
#   b:
#     c: [d,e,f]
# ```
# The output will be:
# ```yaml
# foo:
#   bar:
#     baz:
#       a:
#         b:
#           c: [d,e,f]
# ```
require 'yaml'

module Jekyll
  module KumaPlugins
    module Liquid
      module Blocks
        class HelmValues < ::Liquid::Block
          def initialize(tag_name, markup, options)
            super
            @prefix = markup.strip
          end

          def render(context)
            content = super
            return "" if content.empty?

            site = context.registers[:site]
            site_prefix = site.config['set_flag_values_prefix']

            prefix = (@prefix.empty? ? site_prefix : @prefix).strip.gsub(/^\.+|\.+$/, '')

            ::Liquid::Template.parse(render_yaml(prefix, content)).render(context)
          end

          private

          def render_yaml(prefix, content)
            yaml_raw = content.gsub(/```yaml\n|```/, '')
            yaml_data = YAML.load_stream(yaml_raw).first

            unless prefix.empty?
              prefix.split(".").reverse_each { |part| yaml_data = { part => yaml_data } }
            end

            <<~MARKDOWN
              ```yaml
              #{YAML.dump(yaml_data).gsub(/^---\n/, '').chomp}
              ```
            MARKDOWN
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('helmvalues', Jekyll::KumaPlugins::Liquid::Blocks::HelmValues)
