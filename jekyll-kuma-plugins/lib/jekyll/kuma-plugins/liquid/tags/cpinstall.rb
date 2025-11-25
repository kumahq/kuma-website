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

          # TODO: refactor to reduce complexity
          def render(context)
            content = super
            return '' if content.empty?

            site_data = context.registers[:site].config
            page = context.environments.first['page']

            opts = content.strip.split("\n").map do |x|
              x = site_data['set_flag_values_prefix'] + x if @prefixed
              "--set \"#{x}\""
            end
            res = opts.join(" \\\n  ")

            html_content = "
{% tabs codeblock %}
{% tab kumactl %}
```shell
kumactl install control-plane \\
  #{res} \\
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
  #{res} \\
  {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
```
{:.no-line-numbers}
{% endtab %}
{% endtabs %}"
            ::Liquid::Template.parse(html_content).render(context)
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
