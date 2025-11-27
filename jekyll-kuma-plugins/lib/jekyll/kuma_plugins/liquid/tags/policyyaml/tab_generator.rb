# frozen_string_literal: true

module Jekyll
  module KumaPlugins
    module Liquid
      module Tags
        # Generates HTML tabs for policy YAML display
        class TabGenerator
          def generate(render_context, contents, terraform_content)
            docs_path = build_docs_path(render_context)
            additional_classes = 'codeblock' unless render_context[:use_meshservice]

            html = "{% tabs #{additional_classes} %}"
            html += kubernetes_tab(contents, render_context, docs_path)
            html += universal_tab(contents, render_context, docs_path)
            html += terraform_tab(terraform_content, render_context)
            html += '{% endtabs %}'
            html
          end

          private

          def build_docs_path(render_context)
            version_path = render_context[:release].value
            version_path = 'dev' if render_context[:release].label == 'dev'
            edition = render_context[:edition]

            docs_path = "/#{edition}/#{version_path}"
            docs_path = "/docs/#{version_path}" if edition == 'kuma'
            docs_path
          end

          def kubernetes_tab(contents, render_context, docs_path)
            if render_context[:use_meshservice]
              <<~TAB

                {% tab Kubernetes %}
                <div class="meshservice">
                 <label> <input type="checkbox"> I am using <a href="#{docs_path}/networking/meshservice/">MeshService</a> </label>
                </div>
                #{contents[:kube_legacy]}
                #{contents[:kube]}
                {% endtab %}
              TAB
            else
              <<~TAB

                {% tab Kubernetes %}
                #{contents[:kube_legacy]}
                {% endtab %}
              TAB
            end
          end

          def universal_tab(contents, render_context, docs_path)
            if render_context[:use_meshservice]
              <<~TAB
                {% tab Universal %}
                <div class="meshservice">
                 <label> <input type="checkbox"> I am using <a href="#{docs_path}/networking/meshservice/">MeshService</a> </label>
                </div>
                #{contents[:uni_legacy]}
                #{contents[:uni]}
                {% endtab %}
              TAB
            else
              <<~TAB
                {% tab Universal %}
                #{contents[:uni_legacy]}
                {% endtab %}
              TAB
            end
          end

          def terraform_tab(terraform_content, render_context)
            return '' if render_context[:edition] == 'kuma' || !render_context[:show_tf]

            <<~TAB
              {% tab Terraform %}
              <div style="margin-top: 4rem; padding: 0 1.3rem">
              Please adjust <b>konnect_mesh_control_plane.my_meshcontrolplane.id</b> and
              <b>konnect_mesh.my_mesh.name</b> according to your current configuration
              </div>
              #{terraform_content}
              {% endtab %}
            TAB
          end
        end
      end
    end
  end
end
