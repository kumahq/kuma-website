module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class Embed < ::Liquid::Tag
          def initialize(tag_name, markup, options)
            super
            params = {}
            @file, *params_list = @markup.split(' ')
            params_list.each do |item|
                sp = item.split('=')
                params[sp[0]] = sp[1]
            end
            @versioned = params.has_key?('versioned')
          end

          def render(context)
            base_path = context.registers[:site].config.fetch('mesh_raw_generated_path', 'app/docs')
            ignored_links = context.registers[:site].config.fetch('mesh_ignored_links_regex', [])
            release = context.registers[:page]['release']
            path = File.join(base_path, @versioned ? release : '', @file)

            data = File.read(path) rescue begin
                Jekyll.logger.warn("Failed reading raw file", path)
                return
            end
            ignored_links.each {|re| data = data.gsub(Regexp.new(re), '') }
            return data
          end
        end
      end
    end
  end
end
Liquid::Template.register_tag('embed', Jekyll::KumaPlugins::Liquid::Tags::Embed)
