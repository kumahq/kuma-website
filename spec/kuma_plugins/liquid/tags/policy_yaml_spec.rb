# spec/jekyll/kuma-plugins/liquid/tags/policyyaml_spec.rb
require 'jekyll'
require_relative '../../../../jekyll-kuma-plugins/lib/jekyll/kuma-plugins/liquid/tags/policyyaml'

RSpec.describe Jekyll::KumaPlugins::Liquid::Tags::PolicyYaml do
  let(:content) { <<-YAML
    ```yaml
    apiVersion: kuma.io/v1alpha1
    mesh: default
    kind: TrafficRoute
    metadata:
      name: route-example
      namespace: test
    spec:
      to:
        - targetRef:
            kind: MeshService
            name_uni: example-service
            name_kube: example-service_test_8080
    ```
  YAML
  }

  let(:site) { Jekyll::Site.new(Jekyll.configuration) }
  let(:page) { { 'version' => '2.9.1' } }
  let(:context) { Liquid::Context.new({}, { 'page' => page, 'site' => site }, site) }

  it 'renders universal and kubernetes policy YAMLs' do
    # Simulate parsing and rendering the Liquid tag
    template = Liquid::Template.parse("{% policy_yaml my-tabs %}#{content}{% endpolicy_yaml %}")
    result = template.render(context)

    # Validate that the output contains relevant elements of the YAML
    puts "aa"
    puts result
    puts "bb"
  end
end
