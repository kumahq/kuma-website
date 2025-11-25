# frozen_string_literal: true

require_relative '../../common/params'

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class Inc < ::Liquid::Tag
          include Jekyll::KumaPlugins::Common

          def initialize(_tag_name, markup, _parse_context)
            super

            # Parse parameters, separating recognized defaults and extras
            default_params = { if_version: nil, init_value: 0, get_current: false }
            @name, @params, @extra_params = parse_name_and_params(markup, default_params)
            raise ArgumentError, "The 'inc' tag requires a variable name to increment" if @name.nil?
          end

          def render(context)
            page = context.registers[:page]

            # Ensure nested hash structure exists
            increment_data = page[:plugins] ||= {}
            increment_data = increment_data[:increment] ||= {}

            # Set initial value if not already present
            increment_data[@name] ||= @params[:init_value]

            # Return current value without incrementing if `get_current` is true
            return increment_data[@name] if @params[:get_current]

            # Increment only if should_increment? condition is met
            increment_data[@name] += 1 if should_increment?(context)
            increment_data[@name]
          end

          private

          def should_increment?(context)
            !@params[:if_version] || render_template(context) == 'true'
          end

          def version_check_template
            "{% if_version #{@params[:if_version]} %}true{% endif_version %}"
          end

          def render_template(context)
            ::Liquid::Template.parse(version_check_template).render(context).strip
          rescue ::Liquid::SyntaxError
            log_version_check_error(context)
            ''
          end

          def log_version_check_error(context)
            page_path = context.registers[:page]['path']
            Jekyll.logger.error(
              'Increment Tag Warning:',
              "The 'if_version' condition could not be evaluated in #{page_path}. " \
              "Ensure the 'if_version' plugin is installed."
            )
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('inc', Jekyll::KumaPlugins::Liquid::Tags::Inc)
