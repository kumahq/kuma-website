# frozen_string_literal: true

# This plugin adds key values to install and generates 2 tabs for helm and kumactl.
# It removes duplication of examples for both universal and kubernetes environments.
require 'yaml'
module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class InstallCp < ::Liquid::Block
          def initialize(tag_name, tabs_name, options)
            super
            @tabs_name = tabs_name
            _, *params_list = @markup.split
            params = { 'prefixed' => 'true' }
            params_list.each do |item|
              sp = item.split('=')
              params[sp[0]] = sp[1] unless sp[1] == ''
            end
            @prefixed = params['prefixed'].downcase == 'true'
          end

          def render(context)
            content = super
            return '' if content.empty?

            site_data = context.registers[:site].config
            page = context.environments.first['page']
            helm_flags = process_helm_flags(content, site_data)
            html_content = generate_install_tabs(helm_flags, page)
            ::Liquid::Template.parse(html_content).render(context)
          end

          private

          def process_helm_flags(content, site_data)
            opts = content.strip.split("\n").map do |line|
              line = site_data['set_flag_values_prefix'] + line if @prefixed
              "--set \"#{line}\""
            end
            opts.join(" \\\n  ")
          end

          def generate_install_tabs(helm_flags, page)
            <<~LIQUID

              {% tabs codeblock %}
              {% tab kumactl %}
              ```shell
              kumactl install control-plane \\
                #{helm_flags} \\
                | kubectl apply -f -
              ```
              {:.no-line-numbers}
              {% endtab %}
              {% tab Helm %}
              ```shell
              # Before installing {{ site.mesh_product_name }} with Helm, configure your local Helm repository:
              # {{ site.links.web }}/#{product_url_segment(page)}/{{ page.release }}/production/cp-deployment/kubernetes/#helm
              helm install \\
                --create-namespace \\
                --namespace {{ site.mesh_namespace }} \\
                #{helm_flags} \\
                {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
              ```
              {:.no-line-numbers}
              {% endtab %}
              {% endtabs %}
            LIQUID
          end

          def product_url_segment(page)
            page['dir'].split('/')[1]
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('cpinstall', Jekyll::KumaPlugins::Liquid::Tags::InstallCp)
