# frozen_string_literal: true

require 'erb'
require 'securerandom'

module Jekyll
  module Tabs
    class TabsBlock < Liquid::Block
      def initialize(tag_name, config, tokens)
        super

        @name, options = config.split(' ', 2)
        @options = options.split.each_with_object({}) do |o, h|
          key, value = o.split('=')
          h[key] = value
        end
      end

      def render(context) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        environment = context.environments.first
        environment['tabs'] ||= {}
        file_path = context.registers[:page]['dir']
        environment['tabs'][file_path] ||= {}

        if environment['tabs'][file_path].key? @name
          raise SyntaxError, "There's already a {% tabs %} block with the name '#{@name}'."
        end

        environment['tabs'][file_path][@name] ||= {}
        super

        additional_classes = @options['additionalClasses']&.gsub(/^"|"$/, '')&.strip || ''
        additional_classes = additional_classes.empty? ? '' : " #{additional_classes}"
        ERB.new(self.class.template).result(binding)
      end

      def self.template
        <<~ERB
          <div class="tabs-component<%= additional_classes %>" data-tab="<%= SecureRandom.uuid %>" data-tab-use-url-fragment="<%= options['useUrlFragment'] %>">
            <ul role="tablist" class="tabs-component-tabs">
              <% environment['tabs'][file_path][@name].each_with_index do |(hash, value), index| %>
                <li class="tabs-component-tab <%= index == 0 ? 'is-active' : '' %>" role="presentation">
                  <a
                    aria-controls="<%= hash.rstrip.gsub(' ', '-') %>"
                    aria-selected="<%= index == 0 %>"
                    href="#<%= hash.rstrip.gsub(' ', '-') %>"
                    class="tabs-component-tab-a"
                    role="tab"
                    data-slug="<%= hash.rstrip.gsub(' ', '-') %>"
                  >
                    <%= hash %>
                  </a>
                </li>
              <% end %>
            </ul>

            <div class="tabs-component-panels">
              <% environment['tabs'][file_path][@name].each_with_index do |(key, value), index| %>
                <section
                  aria-hidden="<%= index != 0 %>"
                  class="tabs-component-panel <%= index != 0 ? 'hidden' : '' %>"
                  id="<%= key.rstrip.gsub(' ', '-') %>"
                  role="tabpanel"
                  data-panel="<%= key.rstrip.gsub(' ', '-') %>"
                >
                  <%= value %>
                </section>
              <% end %>
            </div>
          </div>
        ERB
      end
    end

    class TabBlock < Liquid::Block
      alias render_block render

      def initialize(tag_name, markup, tokens)
        super

        @name, @tab = markup.split(' ', 2)
      end

      def render(context) # rubocop:disable Metrics/AbcSize
        site = context.registers[:site]
        converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
        file_path = context.registers[:page]['dir']

        environment = context.environments.first
        environment['tabs'][file_path][@name] ||= {}
        environment['tabs'][file_path][@name][@tab] = converter.convert(render_block(context))
      end
    end
  end
end

Liquid::Template.register_tag('tab', Jekyll::Tabs::TabBlock)
Liquid::Template.register_tag('tabs', Jekyll::Tabs::TabsBlock)
