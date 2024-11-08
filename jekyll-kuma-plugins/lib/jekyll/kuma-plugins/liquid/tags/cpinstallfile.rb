# This plugin simplifies installation documentation by generating tabs for `kumactl`
# and Helm commands, using a set of customizable parameters. It reduces the need for
# duplicate installation examples across Universal and Kubernetes environments.
# The plugin requires a tabs name to be provided, otherwise it will raise an error.

require 'yaml'

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        class CpInstallFile < ::Liquid::Tag
          def initialize(tag_name, text, tokens)
            super
            @tabs_name, *params_list = @markup.split(' ')
            @params = { "filename" => "values.yaml" }

            if @tabs_name.nil? || @tabs_name.strip.empty?
              raise ArgumentError, "You must provide a valid tabs name for the cpinstallfile tag."
            end

            params_list.each do |item|
              key, value = item.split('=')
              @params[key] = value.strip.gsub(/^"+|"+$/, '') if value && !value.empty?
            end
          end

          def render(context)
            ::Liquid::Template.parse(content).render(context)
          end

          private

          def content
            tabs_name = @tabs_name.strip
            filename = @params["filename"]

            <<~MARKDOWN
              {% tabs #{tabs_name} useUrlFragment=false %}
              {% tab #{tabs_name} kumactl %}
              ```sh
              kumactl install control-plane --values #{filename} | kubectl apply -f -
              ```
              {% endtab %}
              {% tab #{tabs_name} Helm %}
              Before using {{site.mesh_product_name}} with Helm, ensure that you’ve followed [these steps](/docs/{{ page.release }}/production/cp-deployment/kubernetes/#helm) to configure your local Helm repository.

              ```sh
              helm install \\
                --create-namespace \\
                --namespace {{site.mesh_namespace}} \\
                --values #{filename} \\
                {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}}
              ```
              {% endtab %}
              {% endtabs %}
            MARKDOWN
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('cpinstallfile', Jekyll::KumaPlugins::Liquid::Tags::CpInstallFile)
