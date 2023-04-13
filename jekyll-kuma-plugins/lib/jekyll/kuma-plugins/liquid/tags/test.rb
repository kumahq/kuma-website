# frozen_string_literal: true

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class Test < ::Liquid::Block

          def render(context) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            text = super
            "<p>#{text} TESTED</p>"
          end

        end
      end
    end
  end
end

Liquid::Template.register_tag('test', Jekyll::KumaPlugins::Liquid::Tags::Test)
