# frozen_string_literal: true

module Jekyll
  class CustomBlock < Liquid::Block
    alias render_block render

    def initialize(tag_name, markup, options)
      super
      @markup = markup.strip
    end

    def render(context)
      site = context.registers[:site]
      converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
      content = converter.convert(render_block(context))

      <<~HTML
        <div class="custom-block #{tag_name}">
          <p>#{content}</p>
        </div>
      HTML
    end
  end
end

Liquid::Template.register_tag('tip', Jekyll::CustomBlock)
Liquid::Template.register_tag('warning', Jekyll::CustomBlock)
Liquid::Template.register_tag('danger', Jekyll::CustomBlock)
