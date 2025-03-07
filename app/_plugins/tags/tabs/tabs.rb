require 'erb'
require 'securerandom'

module Jekyll
  module Tabs
    class TabsBlock < Liquid::Block
      def initialize(tag_name, markup, tokens)
        super

        @class = markup.strip.empty? ? '' : " #{markup.strip}"
      end

      def render(context)
        tabs_id = SecureRandom.uuid
        environment = context.environments.first
        environment["tabs-#{tabs_id}"] = {}
        environment['tabs-stack'] ||= []

        environment['tabs-stack'].push(tabs_id)
        super
        environment['tabs-stack'].pop

        ERB.new(self.class.template).result(binding)
      end

      def self.template
        <<~ERB
          <div class="tabs-component<%= @class %>">
            <ul role="tablist" class="tabs-component-tabs">
              <% environment['tabs-' + tabs_id].each_with_index do |(hash, _), index| %>
                <li class="tabs-component-tab<%= index == 0 ? ' is-active' : '' %>" role="presentation">
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
              <% environment['tabs-' + tabs_id].each_with_index do |(key, value), index| %>
                <section
                  aria-hidden="<%= index != 0 %>"
                  class="tabs-component-panel<%= index != 0 ? ' hidden' : '' %>"
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
        raise SyntaxError, "No toggle name given in #{tag_name} tag" if markup == ''

        @title = markup.strip
      end

      def render(context) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        # Add support for variable titles
        path = @title.split('.')
        # 0 is the page scope, 1 is the local scope
        [0, 1].each do |k|
          next unless context.scopes[k]

          ref = context.scopes[k].dig(*path)
          @title = ref if ref
        end

        site = context.registers[:site]
        converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
        environment = context.environments.first

        tabs_id = environment['tabs-stack'].last
        environment["tabs-#{tabs_id}"][@title] = converter.convert(render_block(context))
      end
    end
  end
end

Liquid::Template.register_tag('tab', Jekyll::Tabs::TabBlock)
Liquid::Template.register_tag('tabs', Jekyll::Tabs::TabsBlock)
