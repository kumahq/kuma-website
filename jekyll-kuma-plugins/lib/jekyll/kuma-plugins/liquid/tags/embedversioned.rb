module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class EmbedVersioned < ::Liquid::Tag
          def initialize(tag_name, markup, options)
            super
            @file = @markup.strip
          end

          def render(context)
            base_path = context.registers[:site].config.fetch('mesh_raw_generated_path', 'app/docs')
            release = context.registers[:page]['release']
            path = "#{base_path}/#{release}/generated/raw/#{@file}"
            File.read(path) rescue begin
                Jekyll.logger.warn("Failed reading raw file", path)
                return
            end
          end
        end
      end
    end
  end
end
Liquid::Template.register_tag('embed_versioned', Jekyll::KumaPlugins::Liquid::Tags::EmbedVersioned)
