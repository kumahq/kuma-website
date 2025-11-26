# frozen_string_literal: true

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class Embed < ::Liquid::Tag
          def initialize(tag_name, markup, options)
            super
            params = {}
            @file, *params_list = @markup.split
            params_list.each do |item|
              sp = item.split('=')
              params[sp[0]] = sp[1]
            end
            @versioned = params.key?('versioned')
          end

          def render(context)
            site_config = context.registers[:site].config
            release = context.registers[:page]['release']
            read_and_filter_content(site_config, release)
          rescue StandardError => e
            Jekyll.logger.warn('Failed reading raw file', e)
            nil
          end

          private

          def read_and_filter_content(site_config, release)
            file_path = resolve_embed_path(release)
            base_paths = site_config.fetch(PATHS_CONFIG, DEFAULT_PATHS)
            content = read_file(base_paths, file_path).read
            apply_link_filter(content, site_config)
          end

          def resolve_embed_path(release)
            version_prefix = @versioned ? release : ''
            File.join(version_prefix, 'raw', @file)
          end

          def apply_link_filter(content, site_config)
            ignored_links = site_config.fetch('mesh_ignored_links_regex', [])
            ignored_links.each { |re| content = content.gsub(Regexp.new(re), '') }
            content
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('embed', Jekyll::KumaPlugins::Liquid::Tags::Embed)
