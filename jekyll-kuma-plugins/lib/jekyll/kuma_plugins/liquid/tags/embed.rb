# frozen_string_literal: true

require_relative '../../common/path_helpers'

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class Embed < ::Liquid::Tag
          include Jekyll::KumaPlugins::Common::PathHelpers

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

          # TODO: refactor to reduce complexity
          def render(context)
            base_paths = context.registers[:site].config.fetch(PATHS_CONFIG, DEFAULT_PATHS)
            ignored_links = context.registers[:site].config.fetch('mesh_ignored_links_regex', [])
            release = context.registers[:page]['release']
            begin
              f = read_file(base_paths, File.join(@versioned ? release : '', 'raw', @file))
              data = f.read
              ignored_links.each { |re| data = data.gsub(Regexp.new(re), '') }
              data
            rescue StandardError => e
              Jekyll.logger.warn('Failed reading raw file', e)
              nil
            end
          end
        end
      end
    end
  end
end
Liquid::Template.register_tag('embed', Jekyll::KumaPlugins::Liquid::Tags::Embed)
