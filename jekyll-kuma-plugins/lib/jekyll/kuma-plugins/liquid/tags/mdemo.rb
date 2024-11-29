module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class MDemo < ::Liquid::Tag
          def initialize(tag_name, markup, options)
            super
          end

          def render(context)
            demo_version = context.registers[:site].config.fetch('mesh_demo_version', 'main')
            return "https://raw.githubusercontent.com/kumahq/kuma-counter-demo/refs/heads/#{demo_version}#{@markup.strip}"
          end
        end
      end
    end
  end
end
Liquid::Template.register_tag('mdemo', Jekyll::KumaPlugins::Liquid::Tags::MDemo)
